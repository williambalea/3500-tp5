-------------------------------------------------------------------------------
-- FILE		: uart.vhd
-- TITLE	: Universal asynchronous receiver trasmitter
-- AUTHOR	: Jeferson Santiago da Silva
-- PURPOSE	: UART interface TX/RX
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
entity uart is
	generic(
		BUS_FREQUENCY	: integer	:= 100_000_000;							-- Bus frequency in Hertz
		BAUD_RATE		: integer 	:= 57_600;								-- Baud rate of transmission
		DATA_WIDTH		: integer	:= 8;									-- UART Data field width
		PARITY_EN		: boolean	:= true;								-- Enables parity check/generation
		PARITY_TYPE		: std_logic	:= '0'									-- Parity type: '0' - even, '1' - odd
	);                                                          			
	port (                                                      			
		-- Control                                              			
		clk				: in	std_logic;									-- Clock
		rst				: in 	std_logic;									-- Reset

		-- TX pins
		tx_sdata		: out 	std_logic;									-- Serial TX data
		tx_pdata		: in 	std_logic_vector(DATA_WIDTH - 1 downto 0);	-- Paralel RX data
		tx_send_data	: in	std_logic;									-- Send data enable
		tx_busy			: out	std_logic;									-- UART TX busy

		-- RX pins
		rx_sdata		: in 	std_logic;									-- Serial data
		rx_pdata		: out	std_logic_vector(DATA_WIDTH - 1 downto 0);	-- Paralel TX data
		rx_pdata_valid	: out	std_logic;									-- Paralel RX data valid
		rx_frame_err	: out	std_logic;									-- Frame error
		rx_parity_err	: out	std_logic									-- Parity error
	);
end uart;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture uart of uart is

	--------------
	-- Function --
	--------------

	-----------
	-- Types --
	-----------
	type uart_tx_fsm is (idle_st, data_st);
	type uart_rx_fsm is (idle_st, sync_st, data_st, parity_st, stop_st);

	---------------
	-- Constants --
	---------------
	constant BR_DIVISOR				: integer := integer(BUS_FREQUENCY/BAUD_RATE);
	constant OVERSAMPLING_COUNTER	: integer := integer(integer(BUS_FREQUENCY/BAUD_RATE)/2);
	
	-------------------------
	-- Signal declarations --
	-------------------------
	signal uart_rx				: uart_rx_fsm := idle_st;			
	signal uart_tx				: uart_tx_fsm := idle_st;
	signal rx_frame_rst         : std_logic;
	signal rx_parity_calc       : std_logic := PARITY_TYPE;
	signal tx_parity_calc       : std_logic := PARITY_TYPE;
	signal rx_uart_clken		: std_logic;
	signal tx_uart_clken		: std_logic;
	signal rx_sdata_sync		: std_logic;
	signal rx_sdata_reg			: std_logic;
	signal rx_falling_edge		: std_logic;
	signal tx_cnt				: unsigned(log2(DATA_WIDTH + 2) - 1 downto 0)	:= (others => '0');
	signal rx_cnt				: unsigned(log2(greater(OVERSAMPLING_COUNTER, DATA_WIDTH + 2)) - 1 downto 0) := (others => '0');
	signal tx_buffer			: std_logic_vector(DATA_WIDTH - 1 downto 0);


begin

	---------------
	-- Port maps --
	---------------
	-- Start Bit detector
	start_bit_detect: entity work.edge_detector
		port map(
			clk		=> clk,
			clken	=> '1',
			rst		=> rst,
			din		=> rx_sdata_sync,
			rising	=> open,
			falling	=> rx_falling_edge,
			edge	=> open
		);
		
	-- RX UART clock generation	
	rx_clk_div: entity work.reg_clken
		generic map(
			CLK_DIV	=> BR_DIVISOR
		)
		port map(
			clk 	    => clk,
			rst		    => rx_frame_rst,
			clken_in    => '1',
			clken_out   => rx_uart_clken
		);

	-- TX UART clock generation	
	tx_clk_div: entity work.reg_clken
		generic map(
			CLK_DIV	=> BR_DIVISOR
		)
		port map(
			clk 	    => clk,
			rst		    => '0',
			clken_in    => '1',
			clken_out   => tx_uart_clken
		);		

	-------------------------------
	-- Asynchronous Assignments --
	-------------------------------
    tx_busy <= '1' when uart_tx /= idle_st or tx_send_data = '1' else '0';

	---------------
	-- Processes --
	---------------
	-- RX FSM
	process(clk)
	begin
		if rising_edge(clk) then
            
			-- Global reset
			if rst = '1' then
				uart_rx			<= idle_st;
				rx_pdata_valid	<= '0';
				rx_pdata		<= (others => '0');
			end if;

			-- Two flops to synchonize
			rx_sdata_reg	<= rx_sdata;
			rx_sdata_sync	<= rx_sdata_reg;
			
			case uart_rx is

				when idle_st	=>
					
					-- Wait for start bit				
					if rx_falling_edge = '1' then
						uart_rx			<= sync_st;
						rx_cnt			<= (others => '0');
						rx_pdata		<= (others => '0');
						rx_parity_calc	<= PARITY_TYPE;
						rx_parity_err	<= '0';
						rx_frame_err	<= '0';
					end if;
					rx_frame_rst	<= '1';
					rx_pdata_valid	<= '0';
					
				when sync_st	=>
					rx_cnt	<= rx_cnt + 1;
					if rx_cnt = OVERSAMPLING_COUNTER then
						uart_rx			<= data_st;
						rx_cnt    		<= (others => '0');
						rx_frame_rst	<= '0';
					end if;
					
				when data_st	=>
					
					if rx_uart_clken = '1' then
						if rx_cnt = DATA_WIDTH - 1 then
							if PARITY_EN then
								uart_rx		<= parity_st;
							else
								uart_rx		<= stop_st;
							end if;
							rx_pdata(to_integer(rx_cnt))	<= rx_sdata_sync;
							rx_parity_calc					<= rx_parity_calc xor rx_sdata_sync;
						else
							rx_cnt							<= rx_cnt + 1;
							rx_pdata(to_integer(rx_cnt))	<= rx_sdata_sync;
							rx_parity_calc					<= rx_parity_calc xor rx_sdata_sync;
						end if;
					end if;
				
				when parity_st		=>
					if rx_uart_clken = '1' then
						if rx_sdata_sync /= rx_parity_calc then
							rx_parity_err	<= '1';
						end if;
					   uart_rx			<= stop_st;
					end if;

				when stop_st		=>
					if rx_uart_clken = '1' then
						if rx_sdata_sync /= '1' then
							rx_frame_err	<= '1';
						end if;
						uart_rx			<= idle_st;
                        rx_pdata_valid    <= '1';
					end if;

					
				when others		=>
					uart_rx			<= idle_st;

			end case;

		end if;
	end process;

	-- TX FSM
	process(clk)
	begin
		if rising_edge(clk) then
			-- Global reset
			if rst = '1' then
				uart_tx		<= idle_st;
				tx_sdata	<= '1';
				--tx_busy		<= '0';
			end if;

			case uart_tx is

				when idle_st	=>
				
					if tx_send_data = '1' then
						tx_cnt			<= (others => '0');
						--tx_busy			<= '1';
						uart_tx			<= data_st;
						tx_buffer		<= tx_pdata;
						tx_parity_calc	<= PARITY_TYPE;
					end if;
					--tx_busy		<= '0';
					tx_sdata	<= '1';

				when data_st	=>
					---tx_busy			<= '1';

					if tx_uart_clken = '1' then
						if tx_cnt = 0 then
							-- Send the start bit
							tx_sdata		<= '0';
							tx_cnt			<= tx_cnt + 1;
						elsif tx_cnt < DATA_WIDTH + 1 then
							-- Send the data
							tx_sdata		<= tx_buffer(to_integer(tx_cnt) - 1);
							tx_parity_calc	<= tx_parity_calc xor tx_buffer(to_integer(tx_cnt) - 1);
							tx_cnt			<= tx_cnt + 1;
						elsif tx_cnt = DATA_WIDTH + 1 and PARITY_EN then
							-- Send the parity bit
							tx_sdata		<= tx_parity_calc;
							tx_cnt			<= tx_cnt + 1;
						else
							-- Send stop bit
							tx_cnt			<= (others => '0');
							tx_sdata		<= '1';
							uart_tx			<= idle_st;
						end if;
					end if;
				when others		=>
					uart_tx			<= idle_st;

			end case;
		end if;
	end process;

end uart;
