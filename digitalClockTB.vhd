-----------------------------------------------------------------------------
----------------  This RTL Code written by Matan Leizerovich  ---------------
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-------			           Digital Clock TestBench			   	      -------
-----------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;

entity digitalClockTB is
end entity digitalClockTB;

architecture sim of digitalClockTB is
	-- Constants --
	constant c_FREQ : natural := 1_000_000; -- The desired frequency is 1MHz to make the test easier
	constant c_DELAY : time := 60 us;
	constant c_PERIOD : time := 20 ns;
	constant c_LOOP_ITERATION : natural := 20;
	
	-- Stimulus signals --
	signal i_clk      : std_logic;
	signal i_reset    : std_logic;
	signal i_set_clk  : std_logic;
	signal i_min_hour : std_logic;
	signal i_up       : std_logic;
	signal i_down     : std_logic;
	
	-- Observed signal --
	signal o_HEX0 : std_logic_vector(6 downto 0);
	signal o_HEX1 : std_logic_vector(6 downto 0);
	signal o_HEX2 : std_logic_vector(6 downto 0);
	signal o_HEX3 : std_logic_vector(6 downto 0);
	signal o_LEDG : std_logic_vector(7 downto 0);

begin
	
	-- Unit Under Test port map --
	UUT : entity work.digitalClock(rtl)
	generic map(g_FREQ => c_FREQ)
	port map (
			CLOCK_50 => i_clk ,
			KEY(0)   => i_reset ,
			KEY(1)   => '1' ,
			KEY(2)   => i_up ,
			KEY(3)   => i_down ,
			SW(0)  	=> i_set_clk ,
			SW(1)  	=> i_min_hour ,
			HEX0 	   => o_HEX0 ,
			HEX1 	   => o_HEX1 , 
			HEX2	   => o_HEX2 ,
			HEX3 	   => o_HEX3 ,
			LEDG 	   => o_LEDG);
			
			
	-- Testbench process --
	p_TB : process
	begin
	
		-- Initial state --
		i_reset <= '0';
		i_set_clk <= '0';
		i_min_hour <= '0';
		i_up <= '1';
		i_down <= '1';
		wait for c_DELAY; 
		
		
		-- Normal mode --
		i_reset <= '1'; -- RESET off		
		wait for c_DELAY * 12; 
		
		-- Set mode --
		i_set_clk <= '1';
		wait for c_DELAY; 
		
		
		-- Simulates push buttons --
		
		-- UP minutes in set mode --
		for i in 0 to c_LOOP_ITERATION loop
			i_up <= '0'; 
			wait for c_DELAY;
			i_up <= '1'; 
			wait for c_DELAY;
		end loop;
		
		-- DOWN minutes in set mode --
		for i in 0 to c_LOOP_ITERATION loop
			i_down <= '0'; 
			wait for c_DELAY;
			i_down <= '1'; 
			wait for c_DELAY;
		end loop;
		
		-- Set mode hours --
		i_min_hour <= '1';
		
		-- UP hours in set mode --
		for i in 0 to c_LOOP_ITERATION loop
			i_up <= '0'; 
			wait for c_DELAY;
			i_up <= '1'; 
			wait for c_DELAY;
		end loop;
		
		-- DOWN hours in set mode --
		for i in 0 to c_LOOP_ITERATION loop
			i_down <= '0'; 
			wait for c_DELAY;
			i_down <= '1'; 
			wait for c_DELAY;
		end loop;
	
		-- Back to normal mode --
		i_min_hour <= '0';
		i_set_clk  <= '0';
	
		wait;
	end process p_TB;
	
	
	-- 50 MHz clock in duty cycle of 50% - 20 ns --
	p_clock : process 
	begin 
		i_clk <= '0'; wait for c_PERIOD/2; -- 10 ns
		i_clk <= '1'; wait for c_PERIOD/2; -- 10 ns
	end process p_clock;

end architecture sim;