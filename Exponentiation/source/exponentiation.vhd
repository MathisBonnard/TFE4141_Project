/*------------------------------------------------------------------------------
TFE4141: RSA accelerator project

Exponentiation module:
Returns msgin_data^key_e mod(key_n) using the Blakley module
It also take care about the last_message flag

Authors: Mathis Bonnard and Oluwatimileyin Olaoye
------------------------------------------------------------------------------*/

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity exponentiation is
	generic (
		C_block_size : integer := 256
	);
	port (
		--input controll
		valid_in	: in STD_LOGIC;
		ready_in	: out STD_LOGIC := '1';
		last_in     : in std_logic;

		--input data
		msgin_data 	: in STD_LOGIC_VECTOR ( C_block_size-1 downto 0 );
		
		--RSA keys
		key_n 		: in STD_LOGIC_VECTOR ( C_block_size-1 downto 0 );
		key_e 		: in STD_LOGIC_VECTOR ( C_block_size-1 downto 0 );

		--ouput controll
		ready_out	: in STD_LOGIC;
		valid_out	: out STD_LOGIC := '0';
		last_out    : out std_logic;

		--output data
		result 		: out STD_LOGIC_VECTOR(C_block_size-1 downto 0) := std_logic_vector(TO_UNSIGNED(0,C_block_size));


		--utility
		clk 		: in STD_LOGIC;
		reset_n 	: in STD_LOGIC
	);
end exponentiation;

architecture expBehave of exponentiation is

    signal CS_1             : std_logic := '0';
    signal CS_2             : std_logic := '0';
    signal msgout_valid_1   : std_logic;
    signal msgout_valid_2   : std_logic;
    signal msgin_ready_1    : std_logic;
    signal msgin_ready_2    : std_logic;
    signal message_c        : STD_LOGIC_VECTOR ( C_block_size-1 downto 0 ) := std_logic_vector(TO_UNSIGNED(1,C_block_size));
    signal message_p     	: STD_LOGIC_VECTOR ( C_block_size-1 downto 0 ):= std_logic_vector(TO_UNSIGNED(0,C_block_size));
    signal partial_result   : std_logic_vector ( C_block_size-1 downto 0 ):= std_logic_vector(TO_UNSIGNED(0,C_block_size));
    signal p_new            : std_logic_vector ( C_block_size-1 downto 0 ):= std_logic_vector(TO_UNSIGNED(0,C_block_size));
    signal computation      : std_logic := '0';

begin

Blakley_1 : entity work.Blakley(Behaviour)
        generic map (
        C_block_size => C_BLOCK_SIZE
        )
        port map (
        A            => message_p,
        B            => message_c,
        n            => key_n,
        R            => partial_result,
        result_ready => msgout_valid_1,
        CS           => CS_1,
        clk          => clk,
        reset_n      => reset_n,
        input_ready  => msgin_ready_1
        );
        
Blakley_2 : entity work.Blakley(behaviour)	
    generic map (
        C_block_size => C_BLOCK_SIZE
        )	
    port map (
        A            => message_p,
        B            => message_p,
        n            => key_n,
        R            => p_new,
        result_ready => msgout_valid_2,
        CS           => CS_2,
        clk          => clk,
        reset_n      => reset_n,
        input_ready  => msgin_ready_2
        );

    Control : process(reset_n, valid_in, valid_out) is
    begin
        if reset_n = '0' then
            computation <= '0';
        elsif valid_in = '1' then
            if valid_out = '0' then
                computation <= '1';     --If input message OK and output message not OK => needs computation
            else
                computation <= '0';     --If input message OK and output message OK => computation over
            end if;
        elsif valid_out = '1' then
            computation <= '0';         --If output message OK => computation over
        end if;
    end process Control;    

    input_control : process(ready_out, valid_in, valid_out, reset_n) is
    begin
        if valid_out = '1' or reset_n ='0' then
            ready_in <= '1';
        elsif valid_in = '1' then
            ready_in <= '0';
        else
            ready_in <= '1';
        end if;
    end process input_control;  
    
    Compute : process(msgout_valid_1, msgout_valid_2, reset_n, computation, msgin_data, key_n, key_e,ready_out,clk) is --msgout_valid_1, msgout_valid_2, reset_n, computation, msgin_data, key_n, key_e,ready_out,clk 
        variable i            : integer := C_block_size-1;
        variable last_message : std_logic;
    begin
        if reset_n = '0' then
            valid_out <= '0';
            i := C_block_size-1;
            CS_1 <= '0';
            CS_2 <= '0';
            message_p <= std_logic_vector(TO_UNSIGNED(0,C_block_size));
            result <= std_logic_vector(TO_UNSIGNED(0,C_block_size));
            
        elsif ready_out = '1' and valid_out='1' then
            if rising_edge(clk) then
                valid_out <= '0';
            end if;
            if falling_edge(clk) then
                valid_out <= '0';
            end if;
            
        elsif computation = '1' then
 
 --Exponentiation alorithm
            if i = C_block_size-1 then      --Needs some cleannig and update before the first multiplication
                message_c <= std_logic_vector(TO_UNSIGNED(1,C_block_size));
                message_p <= msgin_data;
                last_message := last_in;      --Keeps in a register the flag last_in
                valid_out <= '0';
                if(key_e(C_block_size-1-i) = '1') then
                        CS_1<='1';	
                    else 
                        CS_1<='0';
                    end if;
                    CS_2<='1';
                    i := i-1;
                    
            elsif i >= 0 then           --Regular calculus
                if msgout_valid_1 = '1' and msgout_valid_2 = '1' then
                    message_c <= partial_result;
                    message_p <= p_new;
                    if(key_e(C_block_size-1-i) = '1') then
                        CS_1<='1';	
                    else 
                        CS_1<='0';
                    end if;
                    CS_2<='1';
                    i := i-1;
                end if;
 --End of Exponentiation algorithm
                
            else                               -- The result of the computation is ready  
                result <= partial_result;
                valid_out <= '1';
                last_out <= last_message;      --Release the flag last_in kept in a register  
                i := C_block_size-1;
            end if;

        end if;
	end process Compute;  

end expBehave;