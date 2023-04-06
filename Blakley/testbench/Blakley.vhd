--this is an instantiated file
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Blakley_tb is
	generic (
		C_block_size : integer := 256
	);
end Blakley_tb;


architecture behaviour of Blakley_tb is
	
	constant clk_period : time := 10 ns;
	--constant C_block_size : integer := 256;
	
    signal A  : std_logic_vector  ( C_block_size-1 downto 0 ) :=  std_logic_vector(TO_UNSIGNED(0,C_block_size));
    signal B  : std_logic_vector  ( C_block_size-1 downto 0 ) :=  std_logic_vector(TO_UNSIGNED(0,C_block_size));
    signal n  : std_logic_vector  ( C_block_size-1 downto 0 ) :=  std_logic_vector(TO_UNSIGNED(0,C_block_size));
    signal R  : std_logic_vector  ( C_block_size-1 downto 0 ) :=  std_logic_vector(TO_UNSIGNED(0,C_block_size));
    signal CS : std_logic   :='0';
	
	signal clk          : std_logic := '0';
	signal reset_n      : std_logic := '1';
    signal input_ready  : std_logic;
	signal result_ready : std_logic;
	/*
	signal BA_i : std_logic_vector  ( C_block_size downto 0 );
    signal B_ext : std_logic_vector  ( C_block_size downto 0 );
    signal R_ext : std_logic_vector  ( C_block_size downto 0 );
    signal R_BA_i : std_logic_vector  ( C_block_size downto 0 );*/
	
begin
	--i_Blakley : entity work.Blakley
	DUT : entity work.Blakley
		generic map (
			C_block_size => C_block_size
		)
		port map (
			A            => A,
			B            => B,
			n            => n,
			R            => R,
			CS           => CS,
			clk          => clk,
			reset_n      => reset_n,
			input_ready  => input_ready,
			result_ready => result_ready
		);
	
	clk <= not clk after clk_period/2;
	reset_n <= '1';
	
	stimuli: process
	begin
       wait for 1*clk_period;
	   CS<='1';
	   A<=std_logic_vector(TO_UNSIGNED(11110,C_block_size));
	   B<=std_logic_vector(TO_UNSIGNED(1111,C_block_size));
	   n<=std_logic_vector(TO_UNSIGNED(547948,C_block_size));
	   
	   wait for 10*clk_period;
	   wait on result_ready;
	   wait for 10*clk_period;
	   
	   CS<='0';
	   B<=std_logic_vector(TO_UNSIGNED(159111,C_block_size));
	   wait for 100*clk_period;
	   CS <='1';
	   wait on result_ready;
	end process;
	
end behaviour;