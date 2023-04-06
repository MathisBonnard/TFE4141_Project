library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;


entity exponentiation_tb is
	generic (
		C_block_size : integer := 256
	);
end exponentiation_tb;


architecture expBehave of exponentiation_tb is

	constant clk_period : time := 20 ns;
	
	--input controll
    signal valid_in	: STD_LOGIC := '0';
    signal ready_in	: STD_LOGIC;
	signal last_in  : std_logic := '0';


    --input data
    signal msgin_data 	: STD_LOGIC_VECTOR ( C_block_size-1 downto 0 ) :=  std_logic_vector(TO_UNSIGNED(0,C_block_size));
    
    
    signal key_n 		: STD_LOGIC_VECTOR ( C_block_size-1 downto 0 ) :=  std_logic_vector(TO_UNSIGNED(0,C_block_size));
    signal key_e 		: STD_LOGIC_VECTOR ( C_block_size-1 downto 0 ) :=  std_logic_vector(TO_UNSIGNED(0,C_block_size));

    --ouput controll
    signal ready_out	: STD_LOGIC := '0';
    signal valid_out	: STD_LOGIC;
    signal last_out     : std_logic;

    --output data
    signal result 		: STD_LOGIC_VECTOR(C_block_size-1 downto 0);

    --modulus
    --modulus 	: in STD_LOGIC_VECTOR(C_block_size-1 downto 0);

    --utility
    signal clk 		: STD_LOGIC := '0';
    signal reset_n 	: STD_LOGIC := '1';

begin
	--i_exponentiation : entity work.exponentiation
	DUT : entity work.exponentiation
	    generic map (
		C_block_size => C_block_size
	)
		port map (
			msgin_data => msgin_data,
			key_e      => key_e     ,
			valid_in   => valid_in  ,
			ready_in   => ready_in  ,
			ready_out  => ready_out ,
			valid_out  => valid_out ,
			result     => result    ,
			key_n      => key_n     ,
			clk        => clk       ,
			reset_n    => reset_n   ,
			last_in    => last_in   ,
			last_out   => last_out  
		);
    
    clk <= not clk after clk_period/2;
    
    
    stimuli : process is
    begin
        wait for 1*clk_period;
        
	    --result out expected is 11033(d)=2b19(h)
	    valid_in<= '1';
	    ready_out<= '0';
	    msgin_data<=std_logic_vector(TO_UNSIGNED(11110,C_block_size));
	    key_e <=std_logic_vector(TO_UNSIGNED(1111,C_block_size));
	    key_n<=std_logic_vector(TO_UNSIGNED(100001,C_block_size));
	    wait until ready_in = '0';
	    valid_in <= '0';
	    wait on valid_out;
	    wait for 2*clk_period;
	    ready_out <= '1';
	    wait for 20*clk_period;
/*
	    reset_n <= '0';
	    wait for clk_period;
	    reset_n <= '1';*/
	    
	    --result out expected 26936(d)=6938(h)
	    --wait until ready_in = '1';
	    msgin_data<=std_logic_vector(TO_UNSIGNED(11110,C_block_size));
	    key_e <=std_logic_vector(TO_UNSIGNED(1111,C_block_size));
	    key_n<=std_logic_vector(TO_UNSIGNED(179876,C_block_size));
	    valid_in<= '1';
	    ready_out<= '0';
	    wait until ready_in = '0';
	    valid_in <= '0';
	    wait on valid_out;
	    wait for 2*clk_period;
	    ready_out <= '1';
	    wait for 20*clk_period;

        --result out could be 11033 but valid_in is 0.
	    valid_in<= '0';
	    ready_out<= '1';
	    msgin_data<=std_logic_vector(TO_UNSIGNED(11110,C_block_size));
	    key_e <=std_logic_vector(TO_UNSIGNED(1111,C_block_size));
	    key_n<=std_logic_vector(TO_UNSIGNED(100001,C_block_size));
	    wait on valid_out;
	    wait for 20*clk_period;

	    --result out could be 11033 but ready_out is 0.
	    valid_in<= '1';
	    ready_out<= '0';
	    msgin_data<=std_logic_vector(TO_UNSIGNED(11110,C_block_size));
	    key_e <=std_logic_vector(TO_UNSIGNED(1111,C_block_size));
	    key_n<=std_logic_vector(TO_UNSIGNED(100001,C_block_size));
	    wait on valid_out;
	    wait for 20*clk_period;
	    
	end process;
    
end expBehave;


