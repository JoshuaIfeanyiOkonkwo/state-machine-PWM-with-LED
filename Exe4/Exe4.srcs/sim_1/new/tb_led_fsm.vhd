library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_led_fsm is
end tb_led_fsm;

architecture Behavioral of tb_led_fsm is

    -- System clock and controls
    signal clk          : std_logic := '0';
    signal arst_n       : std_logic := '0';
    signal loop_ctrl_in : std_logic := '0';
    signal speed_in     : std_logic_vector(1 downto 0) := "00";

    -- Timer outputs
    signal clk_state_sig : std_logic;
    signal tick_count    : integer range 0 to 1000000 := 0;

    -- Blink timer outputs
    signal blink_tick    : integer range 0 to 1000000;
    signal blink_led     : std_logic;

    -- FSM I/O
    signal dc_out        : std_logic_vector(23 downto 0) := (others => '0');
    signal alarm_in      : std_logic := '0';
    signal state_out     : std_logic_vector(3 downto 0);

    constant CLK_PERIOD : time := 10 ns; 
    constant ZERO_24    : std_logic_vector(23 downto 0) := (others => '0');
    signal mode_str      : string(1 to 8);

    -- Helper function for printing vectors
    function slv_to_string(slv : std_logic_vector) return string is
        variable result : string(1 to slv'length);
    begin
        for i in slv'range loop
            result(i - slv'low + 1) := character'VALUE(std_ulogic'image(slv(i)));
        end loop;
        return result;
    end function;

begin

    -- BlinkTimer
    blink_inst: entity work.blink_timer
      generic map ( BASE_CYCLES => 1 )
      port map (
        clk_in           => clk,
        arst_n           => arst_n,
        speed_in         => speed_in,
        state_out        => state_out,
        alarm_in         => alarm_in,
        loop_ctrl_in     => loop_ctrl_in,
        blink_tick_count => blink_tick,
        blink_clk        => blink_led
      );

    -- Timer (provides FSM clock and tick_count; no alarm_fall/alarm_done ports)
    u_timer: entity work.timer
      generic map ( CLK_PERIOD_CYCLES => 10 )
      port map (
        clk_in     => clk,
        arst_n     => arst_n,
        speed_in   => speed_in,
        state_out  => state_out,
        alarm_in   => alarm_in,
        clk_out    => clk_state_sig
       -- tick_count => tick_count
      );

    -- FSM (consumes timer clock, blink clock, raw alarm_in)
    u_fsm: entity work.led_fsm
      generic map ( STATE_WIDTH => 10 )
      port map (
        clk_in          => clk_state_sig,
        arst_n       => arst_n,
        loop_ctrl_in => loop_ctrl_in,
        blink_clk    => blink_led,
        alarm_in     => alarm_in,
        state_out    => state_out,
        dc_out       => dc_out
      );

    -- System clock generator
    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    -- Stimulus
    stim_proc : process
    begin
        arst_n <= '0';
        wait for 1us;
        arst_n <= '1';
        wait for 100 us;

        speed_in <= "00"; wait for 15 us; report "Speed changed to 00";
        speed_in <= "01"; wait for 35 us; report "Speed changed to 01";
        speed_in <= "10"; wait for 55 us; report "Speed changed to 10";
        speed_in <= "11"; wait for 85 us; report "Speed changed to 11";

        assert false report "Simulation finished." severity note;
        wait;
        
        wait for 500 ns;
        if dc_out = ZERO_24 then
            assert false report "ERROR: dc_out stuck at zero!" severity warning;
        else
            report "PASS: dc_out is changing properly." severity note;
        end if;
        wait;
         -- Assertions for tick_count ranges
        if rising_edge(clk_state_sig) then
            case speed_in is
                when "00" =>
                    if tick_count = 9 then
                        report "PASS: Speed 00 reached tick_count 9" severity note;
                    elsif tick_count > 9 then
                        assert false report "Speed 00 exceeded tick_count" severity error;
                    end if;
                when "01" =>
                    if tick_count = 29 then
                        report "PASS: Speed 01 reached tick_count 29" severity note;
                    elsif tick_count > 29 then
                        assert false report "Speed 01 exceeded tick_count" severity error;
                    end if;
                when "10" =>
                    if tick_count = 49 then
                        report "PASS: Speed 10 reached tick_count 49" severity note;
                    elsif tick_count > 49 then
                        assert false report "Speed 10 exceeded tick_count" severity error;
                    end if;
                when "11" =>
                    if tick_count = 69 then
                        report "PASS: Speed 11 reached tick_count 69" severity note;
                    elsif tick_count > 69 then
                        assert false report "Speed 11 exceeded tick_count" severity error;
                    end if;
                when others =>
                    if state_out = "0100" then
                        if tick_count = 39 then
                            report "PASS: State 4 lasted 40 ticks" severity note;
                        elsif tick_count > 39 then
                            assert false report "FAIL: State 4 exceeded 40 ticks" severity error;
                        end if;
                    elsif state_out = "1000" then
                        if tick_count = 79 then
                            report "PASS: Alarm lasted 80 ticks" severity note;
                        elsif tick_count > 79 then
                            assert false report "FAIL: Alarm exceeded 80 ticks" severity error;
                        end if;
                    end if;
            end case;
        end if;
    
        
        
    end process;

    -- Alarm stimulus
    p_alarm : process
    begin
        alarm_in <= '1';
        wait for 10 us;
        alarm_in <= '0';   -- triggers alarm_fall inside FSM
        wait for 100 us;
    end process;

    -- Loop control stimulus
    p_loop_ctrl : process
    begin
        loop_ctrl_in <= '0';
        report "Loop control set to FORWARD";
        wait for 80 us;

        loop_ctrl_in <= '1';
        report "Loop control set to BACKWARD";
        wait for 100 us;

        loop_ctrl_in <= '0';
        report "Loop control returned to FORWARD";
        wait for 80 us;

        wait;
    end process;

-- Immediate visibility on reset release
reset_monitor : process(arst_n)
begin
  if arst_n = '0' then
    report "RESET asserted";
  else
    report "RESET released at " & time'image(now);
  end if;
end process;

-- Check FSM clock toggling (it must toggle post-reset)
fsmclk_activity : process(clk_state_sig)
begin
  if rising_edge(clk_state_sig) then
    report "FSMCLK rising at " & time'image(now);
  end if;
end process;

-- Confirm alarm falling edge intent
alarm_monitor : process(alarm_in)
begin
  if falling_edge(alarm_in) then
    report "Alarm FALLING EDGE at " & time'image(now);
  end if;
end process;


    -- Monitors
    monitor_sysclk : process(clk)
    begin
        if rising_edge(clk) then
            report "SYSCLK | Tick Count = " & integer'image(tick_count) &
                   " | State = " & slv_to_string(state_out) &
                   " | DC_OUT = " & slv_to_string(dc_out);
        end if;
    end process;

    monitor_fsmclk : process(clk_state_sig)
    begin
        if rising_edge(clk_state_sig) then
            report "FSMCLK | Tick Count = " & integer'image(tick_count) &
                   " | State = " & slv_to_string(state_out) &
                   " | DC_OUT = " & slv_to_string(dc_out);
        end if;
    end process;


    -- Mode string monitor
    process(arst_n, loop_ctrl_in)
    begin
        if arst_n = '0' then
            mode_str <= "RESET   ";
        else
            if loop_ctrl_in = '0' then
                mode_str <= "FORWARD ";
            else
                mode_str <= "BACKWARD";
            end if;
        end if;
    end process;

end Behavioral;
