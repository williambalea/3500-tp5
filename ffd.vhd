library ieee;
	use ieee.std_logic_1164.all;

library work;

entity ffd is 
	generic	(
		DATA_WIDTH	: integer	:= 1;
		CLK_POL		: std_logic	:= '1';
		RST_POL		: std_logic	:= '1';
		RST_VAL		: std_logic	:= '0'
	);
	port (
		clk			: in    std_logic;
		clken		: in    std_logic;
		rst			: in    std_logic;
		
		d			: in    std_logic_vector(DATA_WIDTH - 1 downto 0);
		q			: out   std_logic_vector(DATA_WIDTH - 1 downto 0)
	);
end entity ffd;

architecture ffd of ffd is

begin
	process (clk)
	begin
		if clk'event and clk = CLK_POL then
			if rst = RST_POL then
				q	<= (others => RST_VAL);
			else
				if clken = '1' then
					q	<= d;
				end if;	
			end if;	
		end if;	

	end process;
end architecture ffd;
