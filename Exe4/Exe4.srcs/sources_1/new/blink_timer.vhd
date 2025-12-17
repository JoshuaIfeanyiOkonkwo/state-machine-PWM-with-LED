library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity blink_timer is
  generic (
    BASE_CYCLES : integer := 1  -- blink tick = 1 cycle = 10 ns at 100 MHz
  );
  port (
    clk_in            : in  std_logic;
    arst_n            : in  std_logic;
    speed_in          : in  std_logic_vector(1 downto 0);
    state_out         : in  std_logic_vector(3 downto 0);
    alarm_in          : in  std_logic;  -- raw external alarm input
    loop_ctrl_in      : in  std_logic;  -- 0 = forward, 1 = backward
    blink_clk         : out std_logic;
    blink_tick_count  : out integer range 0 to 1000
  );
end blink_timer;

architecture Behavioral of blink_timer is
  signal counter       : integer := 0;
  signal limit         : integer := BASE_CYCLES * 10;  -- default blink period
  signal clk_div       : std_logic := '0';

  -- edge detector output
  signal alarm_fall_p  : std_logic := '0';
begin

  u_alarm_edge : entity work.edge_detector
    port map (
      clk_in      => clk_in,     -- same domain as blink timer
      arst_n   => arst_n,
      alarm_in => alarm_in,
      fall_p   => alarm_fall_p
    );

  process(clk_in, arst_n)
  begin
    if arst_n = '0' then
      counter <= 0;
      clk_div <= '0';
      limit   <= BASE_CYCLES * 10;
    elsif rising_edge(clk_in) then
      -- base limit selection
      case state_out is
        when "0100" =>
          limit <= BASE_CYCLES * 5;    -- faster blink in state 4
        when "1000" =>
          limit <= BASE_CYCLES * 10;    -- alarm blink: 10× faster
        when others =>
          case speed_in is
            when "00" => limit <= BASE_CYCLES * 10;
            when "01" => limit <= BASE_CYCLES * 15;
            when "10" => limit <= BASE_CYCLES * 20;
            when "11" => limit <= BASE_CYCLES * 25;
            when others => limit <= BASE_CYCLES * 10;
          end case;
      end case;

      -- immediate reaction to falling edge of alarm_in
      if alarm_fall_p = '1' then
        limit <= BASE_CYCLES * 1;  -- force 10× faster blink
        counter <= 0;              -- restart blink cycle
        clk_div <= '1';            -- ensure visible toggle
      end if;

      -- optional: adjust blink timing differently in backward mode
      if loop_ctrl_in = '1' then
        limit <= limit * 2;  -- slow down globally in backward mode
      end if;

      -- counter logic
      if counter < limit - 1 then
        counter <= counter + 1;
      else
        counter <= 0;
        clk_div <= not clk_div;
      end if;
    end if;
  end process;

  blink_tick_count <= counter;
  blink_clk        <= clk_div;
end Behavioral;
