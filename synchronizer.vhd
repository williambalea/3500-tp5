library ieee;
	use ieee.std_logic_1164.all;

library work;

entity synchronizer is 
	generic	(
		CLK_POL		: std_logic	:= '1'
	);
	port (
        clk         : in    std_logic;	
		i			: in    std_logic;
		o			: out   std_logic
	);
end entity synchronizer;

architecture synchronizer of synchronizer is
	signal q_int	: std_logic_vector(2 downto 0);

begin
    
    sync_loop: for i in 0 to 1 generate 
    	sync_gen: entity work.ffd 
    		generic	map (
    			DATA_WIDTH	=> 1,
    			CLK_POL		=> CLK_POL,
    			RST_POL		=> '1',
    			RST_VAL		=> '0'
    		)
    		port map (
    			clk			=> clk,
    			clken		=> '1',
    			rst			=> '0',
    			
    			d(0)		=> q_int(i),
    			q(0)		=> q_int(i+1)
    		);
    end generate;
    
    q_int(0)    <= i;
    o           <= q_int(q_int'high);

end architecture synchronizer;
