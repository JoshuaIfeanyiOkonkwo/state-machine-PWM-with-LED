library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity edge_detector is
    Port (
        clk_in      : in  std_logic;   -- local domain clock (FSM or Timer)
        arst_n   : in  std_logic;   -- async reset, active low
        alarm_in : in  std_logic;   -- raw external alarm input
        fall_p   : out std_logic;    -- one-cycle falling edge pulse
        rise_p   : out std_logic
    );
end edge_detector;

architecture Behavioral of edge_detector is
    -- two-stage synchronizer
    signal sync0, sync1 : std_logic := '1';  -- idle high
    signal prev         : std_logic := '1';  -- previous sync state
begin
    process(clk_in, arst_n)
    begin
        if arst_n = '0' then
            prev   <= '0';
            fall_p <= '0';
        elsif rising_edge(clk_in) then
            -- synchronize raw alarm_in into local clock domain
            prev <= alarm_in;
            -- falling edge detection
            if (prev = '1' and alarm_in = '0') then
                fall_p <= '1';
            else    
                fall_p <= '0';
                rise_p <= '0';
             end if;
        end if;
    end process;
end Behavioral;
