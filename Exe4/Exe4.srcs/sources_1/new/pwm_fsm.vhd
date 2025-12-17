library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pwm_fsm is
  generic (
     PWM_RESOLUTION : integer := 8
  );
  port (
    clk_in     : in  std_logic;
    arst_n     : in  std_logic;
    duty_cycle : in  unsigned(PWM_RESOLUTION-1 downto 0);
    pwm_out    : out std_logic
  );
end entity pwm_fsm;

architecture Behavioral of pwm_fsm is
  signal counter : unsigned(PWM_RESOLUTION-1 downto 0) := (others => '0');
begin
  process(clk_in, arst_n)
  begin
    if arst_n = '0' then
      counter <= (others => '0');
      pwm_out <= '0';
    elsif rising_edge(clk_in) then
      counter <= counter + 1;
      if counter < duty_cycle then
        pwm_out <= '1';
      else
        pwm_out <= '0';
      end if;
    end if;
  end process;
end Behavioral;
