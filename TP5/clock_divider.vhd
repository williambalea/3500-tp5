-----------------------------------------------
-- FILE		: clock_divider.vhd
-- TITLE	: Clock divider
-- AUTHOR	: Jeferson Santiago da Silva
-- PURPOSE	: Generic clock divider by CLK_DIV 
-----------------------------------------------

-------------------------------------------------------------------------------
-- Libraries 
-------------------------------------------------------------------------------
library ieee;
	use ieee.std_logic_unsigned.all;
	use ieee.std_logic_1164.all;
library work;
	use work.common_pkg.all;

-------------------------------------------------------------------------------
-- Entity 
-------------------------------------------------------------------------------
entity clock_divider is
	generic (
		CLK_DIV		: integer := 1			-- Clock divisor
	);
	port (
		clk_in		: in 	std_logic;		-- Clock in
		clken		: in 	std_logic;		-- Clock en
		rst			: in 	std_logic;		-- Reset
		clk_out		: out 	std_logic		-- clock out
	);
end clock_divider;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture clock_divider of clock_divider is

	--------------
	-- Function --
	--------------

	-----------
	-- Types --
	-----------

	---------------
	-- Constants --
	---------------

	-------------------------
	-- Signal declarations --
	-------------------------
	signal clk_out_i	: std_logic := '0';
	signal clk_cnt		: std_logic_vector(log2(integer(CLK_DIV/2)) - 1 downto 0) := (others => '0');

begin
	
	-------------------------------
	-- Asynchronous Assignments --
	-------------------------------
	clk_out		<= clk_in when CLK_DIV = 1 else clk_out_i;

	---------------
	-- Processes --
	---------------
	-- RX FSM
	process(clk_in)
	begin
		if clk_in'event and clk_in = '1' then
		    if clken = '1' then
				if rst = '1' then
			    	clk_out_i 	<= '0';
			    	clk_cnt		<= (others => '0');
			    else
			    
                    if clk_cnt < integer(CLK_DIV/2) then
                        clk_cnt		<= clk_cnt + '1';
                    else
                        clk_out_i	<= not clk_out_i;
                        clk_cnt		<= (others => '0');
                    end if;
                end if;
	        end if;
		end if;
	end process;

end clock_divider;
