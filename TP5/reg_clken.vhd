-----------------------------------------------
-- FILE		: reg_clken.vhd
-- TITLE	: Register-based clock enable generation
-- AUTHOR	: Jeferson Santiago da Silva
-- PURPOSE	: Clock enable generation: clken_out = clken_in/CLK_DIV 
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
entity reg_clken is
	generic (
		CLK_DIV		: integer := 1			-- Clock divisor
	);
	port (
		clk         : in 	std_logic;		-- Clock in
		rst         : in 	std_logic;		-- Reset
    
        clken_in	: in 	std_logic;		-- clock enable in
        clken_out	: out 	std_logic		-- clock enable out
	);
end reg_clken;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture reg_clken of reg_clken is

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
	signal clk_int	: std_logic := '0';

begin

    -------------------------------
    -- Port Maps                 --
    -------------------------------
    clkgen: entity work.clock_divider
    	generic map (
    		CLK_DIV		=> CLK_DIV
    	)
    	port map (
    		clk_in		=> clk,
    		clken       => clken_in,
            rst			=> rst,
    		clk_out		=> clk_int
    	);
    
    reg_gen: entity work.edge_detector
    	port map (
    		-- Control
    		clk			=> clk,
    		clken       => '1',
    		rst			=> rst,
    		-- Data
    		din			=> clk_int,
    		rising		=> clken_out,
    		falling		=> open,
    		edge		=> open
    	);

	-------------------------------
	-- Asynchronous Assignments --
	-------------------------------

	---------------
	-- Processes --
	---------------

end reg_clken;
