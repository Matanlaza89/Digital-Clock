-----------------------------------------------------------------------------
----------------  This RTL Code written by Matan Leizerovich  ---------------
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-------			                Clock Divider				   	      -------
-----------------------------------------------------------------------------
------ This entity divides the frequency of the 50MHz main FPGA clock -------
-----------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clockDivider is
generic(g_FREQ : integer := 1); -- Desired clock frequency , default is 1 hz
port (
		-- Inputs --
		i_clk   : in std_logic;
		i_reset : in std_logic;
		
		-- Outputs --
		o_clk    : out std_logic;
		o_tick   : out std_logic
		);
end entity clockDivider;

architecture rtl of clockDivider is
	-- Constants --
	constant c_50MHZ_CLK : natural := 50_000_000; -- Main fpga's clock
	
	-- Signals --
	signal r_cnt_new_clk : natural range 0 to c_50MHZ_CLK := 0;
	signal r_cnt_tick    : natural range 0 to c_50MHZ_CLK := 0;
	signal s_new_clk     : std_logic := '0';
	signal s_clk_tick    : std_logic := '0';
	
begin
	-- This process creates a new clock with a 50% duty cycle  --
	p_clock_divider : process (i_clk , i_reset) is
	begin
		if (i_reset = '0') then -- asynchronous reset
			r_cnt_new_clk <= 0;
			
		elsif (rising_edge(i_clk)) then
			
			-- A counter that counts the number of the rising edges transitions of the main clock until it reaches half the desired clock frequency to change the value --
			if (r_cnt_new_clk = (c_50MHZ_CLK / 2 / g_FREQ) - 1) then
				r_cnt_new_clk <= 0;
				s_new_clk <= not(s_new_clk);		
				
			else
				r_cnt_new_clk <= r_cnt_new_clk + 1;
				
			end if; -- r_cnt_new_clk
			
		end if; -- i_reset / rising_edge(i_clk)
	end process p_clock_divider;
	
	
	-- New clock signal with a work cycle of 50% --
	o_clk <= s_new_clk;
	
	
	-- This process creates a new clock with a 50% duty cycle --
	p_clock_tick : process (i_clk , i_reset) is
	begin
		if (i_reset = '0') then -- asynchronous reset
			r_cnt_tick <= 0;
			
		elsif (rising_edge(i_clk)) then
			
			-- A counter that counts the number of rising edge transitions of the main clock until it reaches the desired clock frequency to give a single pulse at the output --
			if (r_cnt_tick = (c_50MHZ_CLK / g_FREQ) - 1) then
				r_cnt_tick <= 0;
				s_clk_tick <= '1';	
				
			else
				s_clk_tick <= '0';
				r_cnt_tick <= r_cnt_tick + 1;
				
			end if; -- r_cnt_tick
			
		end if; -- i_reset / rising_edge(i_clk)
	end process p_clock_tick;
	
	-- New clock single pulse signal --
	o_tick <= s_clk_tick;
	
end architecture rtl;