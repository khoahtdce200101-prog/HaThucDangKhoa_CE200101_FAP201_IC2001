library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity lab01_tb is
end entity lab01_tb;

architecture sim of lab01_tb is
    -- Khai báo tín hiệu
    signal i_sw1  : STD_LOGIC := '0';
    signal i_sw2  : STD_LOGIC := '0';
    signal i_sw3  : STD_LOGIC := '0';
    signal o_led1 : STD_LOGIC;
    signal o_led2 : STD_LOGIC;
    signal o_led3 : STD_LOGIC;

begin
    -- Instantiate DUT (Device Under Test)
    dut : entity work.lab01 -- Lưu ý: Tên này phải khớp chính xác với entity của file code chính
        port map (
            i_sw1  => i_sw1,
            i_sw2  => i_sw2,
            i_sw3  => i_sw3,
            o_led1 => o_led1,
            o_led2 => o_led2,
            o_led3 => o_led3
        );

    -- Tạo kịch bản mô phỏng
    stim_proc: process
    begin
        -- Chờ 10ns ở trạng thái ban đầu (tất cả bằng '0')
        wait for 10 ns;

        -- Bật công tắc 1
        i_sw1 <= '1'; i_sw2 <= '0'; i_sw3 <= '0';
        wait for 10 ns;

        -- Bật công tắc 1 và 2
        i_sw1 <= '1'; i_sw2 <= '1'; i_sw3 <= '0';
        wait for 10 ns;

        -- Bật cả 3 công tắc
        i_sw1 <= '1'; i_sw2 <= '1'; i_sw3 <= '1';
        wait for 10 ns;

        -- Dừng mô phỏng
        wait;
    end process;

end architecture sim;