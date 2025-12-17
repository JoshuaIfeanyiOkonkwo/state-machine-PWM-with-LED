library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;  -- needed for unsigned()

entity top is
    Port (
        arst_n        : in  std_logic;  -- raw reset button
        clk_in        : in  std_logic;
        speed_in      : in  std_logic_vector(1 downto 0); -- raw speed buttons
        loop_ctrl_in  : in  std_logic;  -- raw loop button
        alarm_in      : in  std_logic;  -- raw alarm button
        led_r, led_g, led_b  : out std_logic
    );
end top;

architecture Behavioral of top is
    -- internal clocks and FSM signals
    signal clk_state      : std_logic;
    signal clk_blink      : std_logic;
    signal state_internal : std_logic_vector(3 downto 0);
    signal dc_internal    : std_logic_vector(23 downto 0);

    signal pwm_r_out, pwm_g_out, pwm_b_out : std_logic;

    -- debounced signals
    signal arst_db       : std_logic;
    signal alarm_db      : std_logic;
    signal loop_ctrl_db  : std_logic;
    signal speed0_db     : std_logic;
    signal speed1_db     : std_logic;
    signal speed_db      : std_logic_vector(1 downto 0);
    signal arsr          : std_logic;
begin
    
     arsr <= not arst_n; -- invert the reset and keep it low
   
    -- Debounce instances for each raw input
    u_db_reset: entity work.debounce
      generic map (clk_freq => 100_000_000, stable_time => 1)
      port map (
        clk     => clk_in,
        reset_n => '1',     
        button  => arsr,
        result  => arst_db
      );

    u_db_alarm: entity work.debounce
      generic map (clk_freq => 100_000_000, stable_time => 10)
      port map (
        clk     => clk_in,
        reset_n => '1',
        button  => alarm_in,
        result  => alarm_db
      );

    u_db_loop: entity work.debounce
      generic map (clk_freq => 100_000_000, stable_time => 10)
      port map (
        clk     => clk_in,
        reset_n => '1',
        button  => loop_ctrl_in,
        result  => loop_ctrl_db
      );

    u_db_speed0: entity work.debounce
      generic map (clk_freq => 100_000_000, stable_time => 10)
      port map (
        clk     => clk_in,
        reset_n => '1',
        button  => speed_in(0),
        result  => speed0_db
      );

    u_db_speed1: entity work.debounce
      generic map (clk_freq => 100_000_000, stable_time => 10)
      port map (
        clk     => clk_in,
        reset_n => '1',
        button  => speed_in(1),
        result  => speed1_db
      );

    speed_db <= speed1_db & speed0_db;

    -- Timer: generates FSM clock and tick count, handles reset/alarm timing
    timer_inst : entity work.timer
       generic map (CLK_PERIOD_CYCLES => 10000000)   -- ~100 ms at 100 MHz
       port map (
            clk_in     => clk_in,
            arst_n     => arst_db,
            speed_in   => speed_db,
            state_out  => state_internal,
            alarm_in   => alarm_db,
            clk_out    => clk_state
        );

    -- Blink Timer: generates blink clock for alarm blinking
    blink_inst : entity work.blink_timer
       generic map (BASE_CYCLES => 1000000)    -- ~10 ms at 100 MHz
       port map (
            clk_in            => clk_in,
            arst_n            => arst_db,
            speed_in          => speed_db,
            alarm_in          => alarm_db,
            state_out         => state_internal,
            loop_ctrl_in      => loop_ctrl_db,
            blink_clk         => clk_blink,
            blink_tick_count  => open
        );

    -- FSM: consumes timer strobe, blink clock, loop control, alarm signals
    fsm_inst : entity work.led_fsm
        generic map (STATE_WIDTH => 10)
        port map (
            arst_n       => arst_db,
            clk_in       => clk_state,
            loop_ctrl_in => loop_ctrl_db,
            blink_clk    => clk_blink,
            alarm_in     => alarm_db,
            dc_out       => dc_internal,
            state_out    => state_internal
        );

    -- PWM drivers for RGB LEDs
    pwm_r: entity work.pwm_fsm
      generic map (PWM_RESOLUTION => 8)
      port map (
        clk_in     => clk_in,
        arst_n     => arst_db,
        duty_cycle => unsigned(dc_internal(23 downto 16)),
        pwm_out    => pwm_r_out
      );

    pwm_g: entity work.pwm_fsm
      generic map (PWM_RESOLUTION => 8)
      port map (
        clk_in     => clk_in,
        arst_n     => arst_db,
        duty_cycle => unsigned(dc_internal(15 downto 8)),
        pwm_out    => pwm_g_out
      );

    pwm_b: entity work.pwm_fsm
      generic map (PWM_RESOLUTION => 8)
      port map (
        clk_in     => clk_in,
        arst_n     => arst_db,
        duty_cycle => unsigned(dc_internal(7 downto 0)),
        pwm_out    => pwm_b_out
      );

    -- Drive board LEDs (active low)
    led_r <= pwm_r_out; 
    led_g <= pwm_g_out;
    led_b <= pwm_b_out;

end Behavioral;
