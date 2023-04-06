--------------------------------------------------------------------------------
-- Author       : Oystein Gjermundnes
-- Organization : Norwegian University of Science and Technology (NTNU)
--                Department of Electronic Systems
--                https://www.ntnu.edu/ies
-- Course       : TFE4141 Design of digital systems 1 (DDS1)
-- Year         : 2018-2019
-- Project      : RSA accelerator
-- License      : This is free and unencumbered software released into the
--                public domain (UNLICENSE)
--------------------------------------------------------------------------------
-- Purpose:
--   RSA encryption core template. This core currently computes
--   C = M**key_e mod key_n.
--------------------------------------------------------------------------------
/*------------------------------------------------------------------------------
TFE4141: RSA accelerator project

RSA_core:
Returns msgin_data^key_e mod(key_n) using the Exponentiation module
Only one core is used

Authors: Mathis Bonnard and Oluwatimileyin Olaoye
------------------------------------------------------------------------------*/
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity rsa_core is
	generic (
		-- Users to add parameters here
		C_BLOCK_SIZE          : integer := 256
	);
	port (
		-----------------------------------------------------------------------------
		-- Clocks and reset
		-----------------------------------------------------------------------------
		clk                    :  in std_logic;
		reset_n                :  in std_logic;

		-----------------------------------------------------------------------------
		-- Slave msgin interface
		-----------------------------------------------------------------------------
		-- Message that will be sent out is valid
		msgin_valid             : in std_logic;
		-- Slave ready to accept a new message
		msgin_ready             : out std_logic := '0';
		-- Message that will be sent out of the rsa_msgin module
		msgin_data              :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
		-- Indicates boundary of last packet
		msgin_last              :  in std_logic;

		-----------------------------------------------------------------------------
		-- Master msgout interface
		-----------------------------------------------------------------------------
		-- Message that will be sent out is valid
		msgout_valid            : out std_logic := '1';
		-- Slave ready to accept a new message
		msgout_ready            :  in std_logic;
		-- Message that will be sent out of the rsa_msgin module
		msgout_data             : out std_logic_vector(C_BLOCK_SIZE-1 downto 0);
		-- Indicates boundary of last packet
		msgout_last             : out std_logic := '0';

		-----------------------------------------------------------------------------
		-- Interface to the register block
		-----------------------------------------------------------------------------
		key_e_d                 :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
		key_n                   :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
		rsa_status              :  out std_logic_vector(31 downto 0)

	);
end rsa_core;

architecture rtl of rsa_core is

signal hold_msgin  : std_logic_vector(C_block_size-1 downto 0);
signal hold_msgout : std_logic_vector(C_block_size-1 downto 0);
signal hold_key_e  : std_logic_vector(C_block_size-1 downto 0);
signal hold_key_n  : std_logic_vector(C_block_size-1 downto 0);

signal Exp_msgin_ready  : std_logic;
signal Exp_msgin_valid  : std_logic := '0';
signal Exp_msgout_ready : std_logic;
signal Exp_msgout_valid : std_logic;

type state is (WAIT_INPUT, COMPUTING, WAIT_OUTPUT);
signal curr_state, next_state : state;

begin

--------------------------------------------------------------------------------
--RSA_core without using FSM: Works but generate latches

	i_exponentiation : entity work.exponentiation(expBehave)
		generic map (
			C_block_size => C_BLOCK_SIZE
		)
		port map (
			msgin_data => hold_msgin,
			key_e      => hold_key_e,
			valid_in   => Exp_msgin_valid ,
			ready_in   => Exp_msgin_ready ,
			ready_out  => Exp_msgout_ready,
			valid_out  => Exp_msgout_valid,
			result     => hold_msgout,
			key_n      => hold_key_n,
			clk        => clk,
			reset_n    => reset_n,
			last_in    => msgin_last,
			last_out   => msgout_last
		);
		
    Control : process (clk) is
    
    --This variable is '1' when a message is ready to be sent on the output bus (compution over but msgout_ready = '0'):
        variable out_msg_stored : std_logic := '0';
    
    begin
        if msgout_ready = '1' and msgout_valid = '1' then
            out_msg_stored := '0';
       
        elsif Exp_msgout_valid = '1' then
            out_msg_stored := '1';              --It does not have a default value... => Latches
        end if;
        
        
        if Exp_msgin_ready = '1' then
            if hold_msgin /= msgin_data then
                hold_msgin <= msgin_data;
                hold_key_e <= key_e_d;
                hold_key_n <= key_n;
                Exp_msgin_valid <= msgin_valid;
            end if;
        else
            Exp_msgin_valid <= '0';             --Latches genreated for hold_X singals. But this is the aim of these registers
        end if;
        
        
        if out_msg_stored = '1' then
            msgout_valid <= '1';
            msgout_data <= hold_msgout;
            Exp_msgout_ready <= '0';
            
        else
            Exp_msgout_ready <= '1';
            msgout_valid <= '0';
        end if;
        
        
        if Exp_msgout_valid = '1' and Exp_msgin_ready = '1' then
            msgin_ready <= '1';
        elsif hold_msgin /= msgin_data and msgin_valid = '1' then 
            msgin_ready <= '0';               --It does not have a default value... => Latches
        end if;

    end process;

--------------------------------------------------------------------------------
--RSA_core using a FSM: We are facing issues because the msgout_data signal stills Uninitialized
/*
	i_exponentiation : entity work.exponentiation(expBehave)
		generic map (
			C_block_size => C_BLOCK_SIZE
		)
		port map (
			msgin_data => msgin_data,
			key_e      => key_e_d,
			valid_in   => Exp_msgin_valid ,
			ready_in   => Exp_msgin_ready ,
			ready_out  => Exp_msgout_ready,
			valid_out  => Exp_msgout_valid,
			result     => msgout_data,
			key_n      => hold_key_n,
			clk        => clk,
			reset_n    => reset_n,
			last_in    => msgin_last,
			last_out   => msgout_last
		);
    
    FSM_Comb : process(Exp_msgin_ready, Exp_msgout_valid, msgin_valid, msgout_ready, msgin_data, curr_state) is
    begin
        case(curr_state) is
        when WAIT_INPUT =>
            msgin_ready      <= '1';
            msgout_valid     <= '0';
            Exp_msgin_valid  <= '0';
            Exp_msgout_ready <= '0';
            if msgin_valid = '1' and Exp_msgin_ready = '1' then
                next_state <= COMPUTING;
                hold_msgin <= msgin_data;
            else
                next_state <= WAIT_INPUT;
            end if;
            
        when COMPUTING =>
            msgin_ready      <= '0';
            msgout_valid     <= '0';
            Exp_msgin_valid  <= '1';
            Exp_msgout_ready <= '1';
            if Exp_msgout_valid = '1' then
                next_state <= WAIT_OUTPUT;
                msgout_data <= hold_msgout;
            else
                next_state <= COMPUTING;
            end if;    
    
        when WAIT_OUTPUT =>
            msgin_ready      <= '0';
            msgout_valid     <= '1';
            Exp_msgin_valid  <= '0';
            Exp_msgout_ready <= '0';
            if msgout_ready = '1' then
                next_state <= WAIT_INPUT;
            else
                next_state <= WAIT_OUTPUT;
            end if;
            
        when others =>
            msgin_ready      <= '0';
            msgout_valid     <= '0';
            Exp_msgin_valid  <= '0';
            Exp_msgout_ready <= '0';
            next_state <= WAIT_INPUT;
        end case;
    end process FSM_Comb;
    
    FSM_Synch : process(reset_n, clk) is
    begin
        if reset_n = '0' then
            curr_state <= WAIT_INPUT;
        elsif rising_edge(clk) or falling_edge(clk) then --If there is no falling_edge statement, the simulation does not work
            curr_state <= next_state;
        end if;    
    end process FSM_Synch;

                hold_key_e <= key_e_d;
                hold_key_n <= key_n;
                */
 --------------------------------------------------------------------------------
 
	rsa_status   <= (others => '0');   --Not used
	
end rtl;
