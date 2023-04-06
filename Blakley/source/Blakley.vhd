/*------------------------------------------------------------------------------
TFE4141: RSA accelerator project

Blakley module:
Returns A*B mod(n) using the Blakley algorithm

Authors: Mathis Bonnard and Oluwatimileyin Olaoye
------------------------------------------------------------------------------*/

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity Blakley is
	generic (
		C_block_size : integer := 256
	);
	port (
		--input data
		A  : in std_logic_vector  ( C_block_size-1 downto 0 );
		B  : in std_logic_vector  ( C_block_size-1 downto 0 );
		n  : in std_logic_vector  ( C_block_size-1 downto 0 );
		CS : in std_logic;
		
		--output data
		R  : out std_logic_vector  ( C_block_size-1 downto 0 ) := std_logic_vector(TO_UNSIGNED(0,C_block_size));
		
		--control pins
		clk : in std_logic;
		reset_n      : in std_logic;
		input_ready  : out std_logic := '1';
		result_ready : out std_logic := '0'
	);
end Blakley;


architecture behaviour of Blakley is

    signal computing      : std_logic := '0';
    signal no_computation : std_logic := '1';
    
    signal wake_result_ready : std_logic := '0';

begin
    Control : process(A,B,n,CS, result_ready) is
    begin
        if reset_n = '0' then
            no_computation <= '1';
            computing <= '0';
        elsif CS='1' then
            if result_ready = '0' then
                computing <= '1';
            else
                computing <= '0';
            end if;
            no_computation <= '0';
        else
            no_computation <= '1';
            computing <= '0';
        end if;
        
        --If nothing happen to result_ready BUT this process runs, result_ready should take the value '0' => See (*)
        if not(rising_edge(result_ready)) and not(falling_edge(result_ready)) then
            wake_result_ready <= not wake_result_ready;
        end if;
    end process Control;
    
    Compute : process(clk, reset_n, wake_result_ready) is
    
    --We need an index to proceed computation
    variable i: integer := C_block_size-1;
    
    --We need longer register to take care about carry
    variable R_ext  : std_logic_vector  ( C_block_size+1 downto 0 ):= std_logic_vector(TO_UNSIGNED(0,C_block_size+2));
    variable R_BA_i : std_logic_vector  ( C_block_size+1 downto 0 ):= std_logic_vector(TO_UNSIGNED(0,C_block_size+2));
    variable BA_i   : std_logic_vector  ( C_block_size+1 downto 0 ):= std_logic_vector(TO_UNSIGNED(0,C_block_size+2));
    
    begin
        if reset_n = '0' then
            i      := C_block_size-1;
            R_ext  := std_logic_vector(TO_UNSIGNED(0,C_block_size+2));
            R_BA_i := std_logic_vector(TO_UNSIGNED(0,C_block_size+2));
            BA_i   := std_logic_vector(TO_UNSIGNED(0,C_block_size+2));
            R      <= std_logic_vector(TO_UNSIGNED(0,C_block_size));
            
        elsif rising_edge(clk) then
        
            if computing = '1' then
            
--Blakley algorithm
                if i >= 0 then          --the index is greater than 0: still computing
                    result_ready <= '0';
                    input_ready <= '0';
                    if A(i)='1' then
                        BA_i := '0' & '0' & B;
                    else
                        BA_i := std_logic_vector(TO_UNSIGNED(0,C_block_size+2));
                    end if;
                    
                    R_ext  := R_ext(C_block_size downto 0)& '0';        --multiplication by 2
                    R_BA_i := R_ext+BA_i;
                    
                        if R_BA_i>=N then
                            R_BA_i := R_BA_i-N;
                            if R_BA_i>=N then
                                R_BA_i := R_BA_i-N;
                            end if;
                        end if;
                        
                    R_ext := R_BA_i;
                    i := i-1;           --decreasing index
 --End of Blakley alorithm
                    
                else                    --index lower than 0 => computation over
                    R <= R_ext(C_block_size-1 downto 0);
                    i := C_block_size-1;
                    R_ext  := std_logic_vector(TO_UNSIGNED(0,C_block_size+2));
                    R_BA_i := std_logic_vector(TO_UNSIGNED(0,C_block_size+2));
                    BA_i   := std_logic_vector(TO_UNSIGNED(0,C_block_size+2));
                    result_ready <= '1';
                    input_ready <= '1';
                end if;
                
            elsif no_computation = '1' then     --When chip is not selected, should give as output one of the input
                R <= B;
                result_ready <= '1';
                input_ready <= '1';
                
            else --computation over but WAS needed => Result should be available
                result_ready <= '1';
                input_ready  <= '1';
                
            end if;
            
         
        end if;
        
        --(*) result_ready is set in this process so. If it should be set to 0, then one of these conditions will be true
        --((it's a really ugly way to do and it will probably not work on FPGA...))
        if rising_edge(wake_result_ready) then
            result_ready <='0';
        end if;
        if falling_edge(wake_result_ready) then
            result_ready <='0';
        end if;
    end process Compute;
        
end behaviour;