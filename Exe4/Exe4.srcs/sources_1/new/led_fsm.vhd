library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity led_fsm is
    generic (
        STATE_WIDTH : integer := 10   -- integer generic: width of state_out encoding
    );
    Port (
        clk_in          : in  std_logic;
        arst_n       : in  std_logic;
        loop_ctrl_in : in  std_logic;
        blink_clk    : in  std_logic; 
        alarm_in     : in  std_logic;              -- raw external alarm input
        state_out    : out std_logic_vector(3 downto 0);
        dc_out       : out std_logic_vector(23 downto 0)
    );
end led_fsm;

architecture Behavioral of led_fsm is
    -- Define states
    type led_state_type is (
        st_reset, st_1, st_2, st_3, st_4, st_5, st_6, st_7, st_alarm
    );
    signal current_state : led_state_type := st_reset;
    signal next_state    : led_state_type := st_reset;

    -- Edge detector output
    signal alarm_fall_pulse : std_logic;
begin
    -- Edge detector instance (falling edge only)
    u_alarm_edge : entity work.edge_detector
        port map (
            clk_in      => clk_in,
            arst_n   => arst_n,
            alarm_in => alarm_in,
            fall_p   => alarm_fall_pulse
        );

    -- State register
    process(clk_in, arst_n)
    begin
        if arst_n = '0' then
            current_state <= st_reset;
        elsif rising_edge(clk_in) then
            current_state <= next_state;
        end if;
    end process;

    -- Next-state logic
    process(current_state, loop_ctrl_in, alarm_fall_pulse, arst_n)
    begin
--        next_state <= current_state;

        if arst_n = '0' then
            next_state <= st_reset;

        -- enter alarm state on falling edge
        elsif alarm_fall_pulse = '1' then
            next_state <= st_alarm;

        -- once in alarm, Timer enforces 80 ticks then moves to st_4
        elsif current_state = st_alarm then
            next_state <= st_4;

        -- once in state 4, Timer enforces 40 ticks then moves on
        elsif current_state = st_4 then
            next_state <= st_1;  -- resume normal sequence

        -- normal sequencing
        elsif loop_ctrl_in = '0' then   -- FORWARD MODE
            case current_state is
                when st_reset => next_state <= st_4;
                when st_1     => next_state <= st_6;
                when st_6     => next_state <= st_2;
                when st_2     => next_state <= st_3;
                when st_3     => next_state <= st_5;
                when st_5     => next_state <= st_7;
                when st_7     => next_state <= st_1;
                when st_alarm => next_state <= st_4;
                when others   => next_state <= st_1;
            end case;
        else                            -- BACKWARD MODE
            case current_state is
                when st_1     => next_state <= st_6;
                when st_5     => next_state <= st_6;
                when st_6     => next_state <= st_7;
                when st_7     => next_state <= st_3;
                when st_3     => next_state <= st_2;
                when st_2     => next_state <= st_6;
                when st_alarm => next_state <= st_4;
                when others   => next_state <= st_6;
            end case;
        end if;
    end process;

    -- Output logic
    process(current_state, blink_clk)
    begin
        case current_state is
            when st_reset =>
                dc_out <= x"000000";
            when st_1 =>
                dc_out <= x"FF0000"; 
            when st_2 =>
                dc_out <= x"00FF00"; 
            when st_3 =>
                dc_out <= x"0000FF"; 
            when st_4 =>
                dc_out <= x"FFFFFF";
            when st_5 =>
                dc_out <= x"FFFF00"; 
            when st_6 =>
                dc_out <= x"00FFFF"; 
            when st_7 =>
                dc_out <= x"800080"; 
            when st_alarm =>
                if blink_clk = '1' then
                    dc_out <= x"FFFFFF";  
                else
                    dc_out <= x"000000";  
                end if;
            when others =>
                dc_out <= x"000000";
        end case;
    end process;

    -- State encoding output (integer → std_logic_vector of generic width)
    state_out <= std_logic_vector(to_unsigned(led_state_type'pos(current_state), 4));
end Behavioral;
