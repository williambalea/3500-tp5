-------------------------------------------------------------------------------
-- FILE		: display.vhd
-- TITLE	: 7-segments display
-- AUTHOR	: Jeferson Santiago da Silva
-- PURPOSE	: 
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Libraries 
-------------------------------------------------------------------------------
library ieee;
	use ieee.std_logic_1164.all;
	use ieee.math_real.all;
	use ieee.numeric_std.all;
library work;
	use work.common_pkg.all;

-------------------------------------------------------------------------------
-- Entity 
-------------------------------------------------------------------------------
entity display is
	generic(
		CLK_FREQUENCY	: integer	:= 100_000_000;							-- Clock frequency in Hertz
		DISPLAY_NUM		: integer	:= 8;									-- Number of displays
        DISPLAY_FORMAT  : string    := "CHAR"                               -- Display format: "CHAR" or "BCD"
	);                                                          			
	port (                                                      			
		-- Control                                              			
		clk				: in	std_logic;									-- Clock

		-- Message
        message         : in    vector8(DISPLAY_NUM - 1 downto 0);          -- Display message       	

		-- Display
		cathods 		: out 	std_logic_vector(6 downto 0);               -- 0: A, ..., 6:G 
		enable  		: out	std_logic_vector(DISPLAY_NUM - 1 downto 0)	-- Display enable
	);
end display;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture display of display is

	--------------
	-- Function --
	--------------
    function to7seg_char(c: character) return std_logic_vector is
    variable v : std_logic_vector(6 downto 0);
    begin
    	case c is
    		when 'a' | 'A' => v := "0001000";
    		when 'b' | 'B' => v := "0000011";	  
    		when 'c' | 'C' => v := "1000110";	  
    		when 'd' | 'D' => v := "0100001";	  
    		when 'e' | 'E' => v := "0000110";	  
    		when 'f' | 'F' => v := "0001110";	  
    		when 'g' | 'G' => v := "0010000";	  
    		when 'h' | 'H' => v := "0001001";	  
    		when '0' => v :="1000000";
    		when '1' => v :="1111001";
    		when '2' => v :="0100100";
    		when '3' => v :="0000110";
    		when '4' => v :="0011001";
    		when '5' => v :="0010010";
    		when '6' => v :="0000010";
    		when '7' => v :="1111000";
    		when '8' => v :="0000000";
    		when '9' => v :="0010000";
    		when others => v :="1111111";
    		
    	end case;
    	
    	return v;
    
    end;
    
    function to7seg(i: std_logic_vector) return std_logic_vector is
    variable v : std_logic_vector(6 downto 0);
    begin
    	case to_integer(unsigned(i)) is
    		
    		when 0 => v :="1000000";
            when 1 => v :="1111001";
            when 2 => v :="0100100";
            when 3 => v :="0000110";
            when 4 => v :="0011001";
            when 5 => v :="0010010";
            when 6 => v :="0000010";
            when 7 => v :="1111000";
            when 8 => v :="0000000";
            when 9 => v :="0010000";    		
    		when others => v :="1111111";
    		
    	end case;
    	
    	return v;
    
    end;
	-----------
	-- Types --
	-----------

	---------------
	-- Constants --
	---------------
	
	-------------------------
	-- Signal declarations --
	-------------------------
	signal cnt              : unsigned(log2(DISPLAY_NUM) - 1 downto 0) := (others => '0');
    signal clken_1khz       : std_logic;

begin

	---------------
	-- Port maps --
	---------------
	-- 1kHz Generation
	rx_clk_div: entity work.reg_clken
		generic map(
			CLK_DIV	=> CLK_FREQUENCY/1_000
		)
		port map(
			clk 	    => clk,
			rst		    => '0',
			clken_in    => '1',
			clken_out   => clken_1khz
		);

	-------------------------------
	-- Asynchronous Assignments --
	-------------------------------

	---------------
	-- Processes --
	---------------
	process(clk)
	begin
		if rising_edge(clk) then
            if clken_1khz = '1' then
                if DISPLAY_FORMAT = "CHAR" then
                    cathods <= to7seg_char(character'val(to_integer(unsigned(message(to_integer(cnt))))));
                else
                    cathods <= to7seg(message(to_integer(cnt)));
                end if;
		        enable      <= (others => '0');
		        enable(to_integer(cnt)) <= '1';
                
                if cnt = DISPLAY_NUM - 1 then
                    cnt <= (others => '0');
                else
                    cnt <= cnt + 1;
                end if;
            end if;

		end if;
	end process;

end display;
