-----------------------------------------------------------------------------
----------------  This RTL Code written by Matan Leizerovich  ---------------
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-------			               Digital Clock        			   	    -------
-----------------------------------------------------------------------------
------ 		 This entity creates a digital clock which displays        ------
------ 				the time with the option to set the time             ------
-----------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity digitalClock is
generic (g_FREQ : integer := 1);
port(
		-- Inputs --
		CLOCK_50 : in std_logic;
		KEY 		: in std_logic_vector (3 downto 0);
		SW			: in std_logic_vector (1 downto 0);
		
		-- Outputs --
		HEX0   : out std_logic_vector(6 downto 0);
		HEX1   : out std_logic_vector(6 downto 0);
		HEX2   : out std_logic_vector(6 downto 0);
		HEX3   : out std_logic_vector(6 downto 0);
		LEDG   : out std_logic_vector(7 downto 0) 
	 );
end entity digitalClock;

architecture rtl of digitalClock is
	-- Functions --
	
	-- Displays the 12 bit binray counter on the 7 segments --
	function binaryTo7Segment (counter:std_logic_vector(11 downto 0)) return std_logic_vector is
		begin
			case (counter) is
				when X"000" => return "1000000"; -- 0
				when X"001" => return "1111001"; -- 1
				when X"002" => return "0100100"; -- 2
				when X"003" => return "0110000"; -- 3
				when X"004" => return "0011001"; -- 4
				when X"005" => return "0010010"; -- 5
				when X"006" => return "0000010"; -- 6
				when x"007" => return "1111000"; -- 7
				when x"008" => return "0000000"; -- 8
				when x"009" => return "0010000"; -- 9
				when x"00A" => return "0001000"; -- a
				when x"00B" => return "0000011"; -- b
				when x"00C" => return "1000110"; -- c
				when x"00D" => return "0100001"; -- d
				when x"00E" => return "0000110"; -- e
				when x"00F" => return "0001110"; -- f
			   when others => return "UUUUUUU"; -- 0
			end case;
	end function binaryTo7Segment;

	-- Aliases --
	alias RESET : std_logic is KEY(0);
	alias SET_CLK : std_logic is SW(0); -- Normal mode '0' , Set mode '1'
 	alias MIN_HOUR : std_logic is SW(1); -- MIN '0' , HOUR '1'
	alias UP : std_logic is KEY(2);
	alias DOWN : std_logic is KEY(3);
	
	-- Constants --
	constant c_SEC_IN_MIN : natural := 60;
	constant c_MAX_MIN : natural := 59;
	constant c_MAX_HOUR : natural := 23;
	
	-- Signals --
	signal r_CNT_SEC : natural range 0 to c_SEC_IN_MIN := 0;
	signal r_CNT_MIN : natural range 0 to c_MAX_MIN := 0;
	signal r_CNT_HOUR : natural range 0 to c_MAX_HOUR := 0;
	
	signal r_SET_MIN : natural range 0 to c_MAX_MIN := 0;
	signal r_SET_HOUR : natural range 0 to c_MAX_HOUR := 0;
	
	signal f_isSetMode : boolean := false; -- Flag for clock mode
	
	signal w_1hz_clk : std_logic;
	signal w_1hz_tick : std_logic;
	
	signal r_UP : std_logic := '0';
	signal r_DOWN : std_logic := '0';
	signal r_set_clk : std_logic := '0';
	
begin
	
	------- Instance of clock divider to create 1 second -------
	i_1Hz_clk : entity work.clockDivider
	generic map(g_FREQ => g_FREQ)
	port map (
			i_clk   => CLOCK_50 ,
			i_reset => RESET ,  
			o_clk   => w_1hz_clk,
			o_tick  => w_1hz_tick);
	-------------------------------------------------------------

	
	-- Digital clock normal mode process --
	p_runing_clock: process(w_1hz_clk , RESET) is
	begin
		if (RESET = '0') then -- asynchronous reset
			r_CNT_SEC  <= 0;	
			r_CNT_MIN  <= 0;
			r_CNT_HOUR <= 0;
		
		elsif (f_isSetMode = true) then
			r_CNT_SEC <= 0;
			r_CNT_MIN <= r_SET_MIN;
			r_CNT_HOUR <= r_SET_HOUR;
			
		elsif (rising_edge(w_1hz_tick)) then -- 1 second has passed

			if(r_CNT_SEC = c_SEC_IN_MIN - 1) then -- r_CNT_SEC == 59 ?
				r_CNT_SEC <= 0;
			
				if(r_CNT_MIN = c_MAX_MIN) then  --  r_CNT_MIN == 59 ?
					r_CNT_MIN <= 0;
					
					if(r_CNT_HOUR = c_MAX_HOUR) then -- r_CNT_HOUR = 23 ?
						r_CNT_HOUR <= 0;
						
					else	
						r_CNT_HOUR <= r_CNT_HOUR + 1;
						
					end if; -- r_CNT_HOUR
					
				else
					r_CNT_MIN <= r_CNT_MIN + 1;
					
				end if; -- r_CNT_MIN
			
			else
				r_CNT_SEC <= r_CNT_SEC + 1;
		
			end if; -- r_CNT_SEC

		end if; -- RESET/rising_edge(w_1hz_tick)
		
	end process p_runing_clock;
	
	
	-- Digital clock set mode process --
	p_set_clock: process (CLOCK_50,RESET,UP,DOWN) is
	begin
		if (RESET = '0') then -- asynchronous reset
			r_SET_MIN  <= 0;
			r_SET_HOUR <= 0;
			
		elsif (rising_edge(CLOCK_50)) then
			-- Sample the last state of the buttons & switch --
			r_UP   <= UP;
			r_DOWN <= DOWN;
			r_set_clk <= SET_CLK;
			
			if(SET_CLK = '1' and r_set_clk ='0') then
				r_SET_MIN <= r_CNT_MIN; 
				r_SET_HOUR <= r_CNT_HOUR;
				
			end if; --SET_CLK and r_set_clk , update last clock for the set time
			
			if (SET_CLK = '1' and MIN_HOUR = '0') then -- Change minutes
				f_isSetMode <= true;
				
				if (UP = '0' and r_UP = '1') then -- Falling edge detector - pressed up button
					if(r_SET_MIN = c_MAX_MIN) then
						r_SET_MIN <= 0;
						
					else
						r_SET_MIN <= r_SET_MIN + 1;
						
					end if; -- r_SET_MIN
				
				elsif (DOWN = '0' and r_DOWN = '1') then -- Falling edge detector - pressed down button
				
					if(r_SET_MIN = 0) then
						r_SET_MIN <= c_MAX_MIN;
						
					else
						r_SET_MIN <= r_SET_MIN - 1;
						
					end if; -- r_SET_MIN
					
				end if; -- UP/DOWN
			
			elsif (SET_CLK = '1' and MIN_HOUR = '1') then -- Change hours
				f_isSetMode <= true;
				
				if (UP = '0' and r_UP = '1') then -- Falling edge detector - pressed up button
					if(r_SET_HOUR = c_MAX_HOUR) then
						r_SET_HOUR <= 0;
						
					else
						r_SET_HOUR <= r_SET_HOUR + 1;
						
					end if; -- r_SET_HOUR
			
				elsif (DOWN = '0' and r_DOWN = '1') then -- Falling edge detector - pressed down button
					
					if(r_SET_HOUR = 0) then
						r_SET_HOUR <= c_MAX_HOUR;
						
					else
						r_SET_HOUR <= r_SET_HOUR - 1;
						
					end if; -- r_SET_HOUR
					
				end if; -- UP/DOWN
				
			else
				f_isSetMode <= false;
				
			end if; -- SET_CLK and MIN_HOUR
		
		end if; -- RESET / rising_edge(CLOCK_50)
	
	end process p_set_clock;
	
	
	---------------------------
	-- Display Digital Clock --
	---------------------------
	
	-- Display the seconds of the digital clock in the green LEDs --
	LEDG <= std_logic_vector(to_unsigned(r_CNT_SEC,8));

	-- Display the minutes of the digital clock --
	HEX1 <= binaryTo7Segment(std_logic_vector(to_unsigned( (r_SET_MIN / 10) ,12 ))) when  f_isSetMode else binaryTo7Segment(std_logic_vector(to_unsigned( (r_CNT_MIN / 10) ,12 )));
	HEX0 <= binaryTo7Segment(std_logic_vector(to_unsigned( (r_SET_MIN mod 10) ,12 ))) when f_isSetMode else binaryTo7Segment(std_logic_vector(to_unsigned( (r_CNT_MIN mod 10) ,12 )));
	
	-- Display the hours of the digital clock --
	HEX3 <= binaryTo7Segment(std_logic_vector(to_unsigned( (r_SET_HOUR / 10) ,12 ))) when f_isSetMode else binaryTo7Segment(std_logic_vector(to_unsigned( (r_CNT_HOUR / 10) ,12 )));
	HEX2 <= binaryTo7Segment(std_logic_vector(to_unsigned( (r_SET_HOUR mod 10) ,12 ))) when f_isSetMode else binaryTo7Segment(std_logic_vector(to_unsigned( (r_CNT_HOUR mod 10) ,12 )));

end architecture rtl;