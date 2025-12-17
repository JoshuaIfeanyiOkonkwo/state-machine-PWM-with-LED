library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity timer is
  generic (
    CLK_PERIOD_CYCLES : integer := 10 
  );
  port (
    clk_in     : in  std_logic;
    arst_n     : in  std_logic;
    speed_in   : in  std_logic_vector(1 downto 0);
    state_out  : in  std_logic_vector(3 downto 0);  -- FSM state input
    alarm_in   : in  std_logic;                     -- external alarm trigger
    clk_out    : out std_logic                    -- FSM clock: high first half, low second half
  );
end entity timer;

architecture Behavioral of timer is
  -- Counters and limits
  signal raw_counter         : integer := 0;
  signal raw_limit_cycles    : integer := 100;
  signal logical_limit_ticks : integer := 10;
  signal half_ticks          : integer := 5;
  signal tick_count          : integer range 0 to 1000000;
  signal clk_div             : std_logic := '0';
 -- signal  tick_count         : integer range 0 to 1000000;  

  -- Change detection
  signal prev_speed          : std_logic_vector(1 downto 0) := "00";
  signal prev_state          : std_logic_vector(3 downto 0) := (others => '0');

  -- Edge detector output
  signal alarm_fall_pulse    : std_logic := '0';
begin

  u_edge_det : entity work.edge_detector
    port map (
      clk_in      => clk_in,
      arst_n   => arst_n,
      alarm_in => alarm_in,
      fall_p   => alarm_fall_pulse
    );

  speed_logic_proc : process(speed_in, state_out)
  begin
    if state_out = "0100" then         -- st_4
      logical_limit_ticks <= 40;
    elsif state_out = "1000" then      -- st_alarm
      logical_limit_ticks <= 80;
    else
      case speed_in is
        when "00"    => logical_limit_ticks <= 10;
        when "01"    => logical_limit_ticks <= 30;
        when "10"    => logical_limit_ticks <= 50;
        when "11"    => logical_limit_ticks <= 70;
        when others  => logical_limit_ticks <= 10;
      end case;
    end if;
  end process;

  clk_gen_proc : process(clk_in, arst_n)
    variable next_tick : integer;
  begin
    if arst_n = '0' then
      raw_counter      <= 0;
      half_ticks       <= 0;
      raw_limit_cycles <= 0;
      tick_count       <= 0;
      clk_div          <= '0';
      prev_speed       <= (others => '0');
      prev_state       <= (others => '0');

    elsif rising_edge(clk_in) then
      half_ticks       <= logical_limit_ticks / 2;
      raw_limit_cycles <= logical_limit_ticks * CLK_PERIOD_CYCLES;

      if (speed_in /= prev_speed) or (state_out /= prev_state) or (alarm_fall_pulse = '1') then
        prev_speed  <= speed_in;
        prev_state  <= state_out;
        raw_counter <= 0;
        tick_count  <= 0;
        clk_div     <= '1';
      else
        if raw_counter < raw_limit_cycles - 1 then
          raw_counter <= raw_counter + 1;

          if (raw_counter mod CLK_PERIOD_CYCLES) = 0 then
            if tick_count < logical_limit_ticks - 1 then
              next_tick := tick_count + 1;
            else
              next_tick := logical_limit_ticks - 1;
            end if;
            tick_count <= next_tick;

            if next_tick = half_ticks then
              clk_div <= '0';
            end if;
          end if;
        else
          raw_counter <= 0;
          tick_count  <= 0;
          clk_div     <= '1';
        end if;
      end if;
    end if;
  end process;

  --tick_count <= tick_index;
  clk_out    <= clk_div;

end Behavioral;
