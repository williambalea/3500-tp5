-----------------------------------------------
-- FILE		: edge_detector.vhd
-- TITLE	: Edge detector
-- AUTHOR	: Jeferson Santiago da Silva
-- PURPOSE	: Edge detector
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
entity edge_detector is
    generic (
        SYNCHRONIZE_INPUTS  : boolean := false  -- Synchronize inputs
    );
	port(
		-- Control
		clk			: in	std_logic;		-- Clock
		clken		: in	std_logic;		-- Clock enable
		rst			: in 	std_logic;		-- Reset
		-- Data
		din			: in 	std_logic;		-- Input data
		rising		: out 	std_logic;		-- Rising edge detected
		falling		: out 	std_logic;		-- Falling edge detected
		edge		: out	std_logic		-- Edge detected
	);
end edge_detector;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture edge_detector of edge_detector is

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
	signal din_int		: std_logic;
	signal din_reg		: std_logic;

begin
    
    ---------------
    -- Port Maps --
    ---------------
    sync_gen: if SYNCHRONIZE_INPUTS generate
        sync: entity work.synchronizer 
        	generic	map(
        		CLK_POL		=> '1'
        	)
        	port map (
                clk         => clk,  
        		i			=> din,
        		o			=> din_int
        	);
    end generate;
	
	-------------------------------
	-- Asynchronous Assignments --
	-------------------------------
    sync_ngen: if not SYNCHRONIZE_INPUTS generate
        din_int <= din;
    end generate;

	falling		<= '1'	when din_reg = '1' and din_int = '0' else '0';
	rising		<= '1'	when din_reg = '0' and din_int = '1' else '0';
	edge		<= '1'	when (din_reg = '1' and din_int = '0') or (din_reg = '0' and din_int = '1') else '0';

	---------------
	-- Processes --
	---------------
	process(clk)
	begin
		if clk'event and clk = '1' then
			if clken = '1' then
                if rst = '1' then
			    	din_reg <= '0';
			    end if;
			    din_reg	<= din_int;
		    end if;
		end if;
	end process;

end edge_detector;
