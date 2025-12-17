library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_debounce is
end tb_debounce;

architecture Behavioral of tb_debounce is
    -- DUT signals
    signal clk     : std_logic := '0';
    signal reset_n : std_logic := '0';
    signal button  : std_logic := '1';  -- idle high
    signal result  : std_logic;

    constant CLK_PERIOD : time := 20 ns;  -- 50 MHz clock
begin
    uut: entity work.debounce
        generic map (
            clk_freq    => 50_000_000,  -- 50 MHz
            stable_time => 10           -- 10 ms stable time
        )
        port map (
            clk     => clk,
            reset_n => reset_n,
            button  => button,
            result  => result
        );

    clk_process : process
    begin
        while true loop
            clk <= '0';
            wait for CLK_PERIOD/2;
            clk <= '1';
            wait for CLK_PERIOD/2;
        end loop;
    end process;

    stim_proc : process
    begin
        -- Hold reset low
        reset_n <= '0';
        wait for 200 ns;
        reset_n <= '1';
        report "Reset released";

        -- Test case 1: clean press and release
        wait for 100 ns;
        button <= '0';  -- press
        wait for 15 ms; -- longer than stable_time
        assert result = '0'
          report "FAIL: result did not go low after stable press"
          severity error;

        button <= '1';  -- release
        wait for 15 ms;
        assert result = '1'
          report "FAIL: result did not return high after release"
          severity error;

        -- Test case 2: bouncing press
        wait for 100 ns;
        button <= '0';
        wait for 1 ms;
        button <= '1';  -- bounce
        wait for 1 ms;
        button <= '0';  -- stable press
        wait for 15 ms;
        assert result = '0'
          report "FAIL: result did not settle low after bounce"
          severity error;

        -- Test case 3: long hold
        wait for 20 ms;
        assert result = '0'
          report "FAIL: result changed unexpectedly during long hold"
          severity error;

        -- Test case 4: multiple presses
        button <= '1';
        wait for 15 ms;
        assert result = '1'
          report "FAIL: result did not go high after release"
          severity error;

        button <= '0';
        wait for 15 ms;
        assert result = '0'
          report "FAIL: result did not go low after second press"
          severity error;

        -- End simulation
        wait for 20 ms;
        assert false report "Simulation finished successfully." severity note;
        wait;
    end process;

    monitor_proc : process(clk)
    begin
        if rising_edge(clk) then
            report "Time=" & time'image(now) &
                   " button=" & std_logic'image(button) &
                   " result=" & std_logic'image(result);
        end if;
    end process;
end Behavioral;
