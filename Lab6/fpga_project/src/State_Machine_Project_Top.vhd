library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity State_Machine_Project_Top is
  port (
    i_Clk       : in  std_logic; -- Chân T9 (50MHz)
    -- 3 nút nhấn trên kit ACG525 (Active-Low: nhấn = '0')
    i_Switch_1  : in  std_logic; -- KEY0 (B16)
    i_Switch_2  : in  std_logic; -- KEY1 (A15)
    i_Switch_3  : in  std_logic; -- KEY2 (C15)
    -- 3 bóng LED đơn trên kit ACG525
    o_LED_1     : out std_logic; -- LED0 (D14)
    o_LED_2     : out std_logic; -- LED1 (C14)
    o_LED_3     : out std_logic; -- LED2 (B9)
    o_LED_4     : out std_logic;
    -- Giao tiếp 74HC595 điều khiển LED 7 đoạn trên kit ACG525
    o_SEG7_DIO  : out std_logic; -- F4
    o_SEG7_RCLK : out std_logic; -- F3
    o_SEG7_SCLK : out std_logic  -- H4
  );
end entity State_Machine_Project_Top;

architecture RTL of State_Machine_Project_Top is

  constant CLKS_PER_SEC   : integer := 50000000; -- 50 MHz
  constant DEBOUNCE_LIMIT : integer := 500000;   -- 10 ms
  constant GAME_LIMIT     : integer := 7;        -- Độ dài tối đa 7 lần nháy

  signal w_Switch_1_In, w_Switch_2_In, w_Switch_3_In : std_logic;
  signal w_Switch_1, w_Switch_2, w_Switch_3          : std_logic;
  signal w_Score                                     : std_logic_vector(3 downto 0);

  signal w_Seg_A, w_Seg_B, w_Seg_C, w_Seg_D, w_Seg_E, w_Seg_F, w_Seg_G : std_logic;
  signal w_Seg_Byte  : std_logic_vector(7 downto 0);
  signal w_Shift_Reg : std_logic_vector(15 downto 0);

  -- Tín hiệu chia xung và dịch bit cho 74HC595
  signal r_Clk_Div : unsigned(9 downto 0) := (others => '0');
  signal r_Bit_Cnt : integer range 0 to 16 := 0;
  signal r_SCLK    : std_logic := '0';
  signal r_RCLK    : std_logic := '0';
  signal r_DIO     : std_logic := '0';

begin
  o_LED_4 <= '0';
  -- Đảo mức logic nút nhấn vì phím trên board ACG525 là Active-Low (nhấn = 0)
  w_Switch_1_In <= not i_Switch_1;
  w_Switch_2_In <= not i_Switch_2;
  w_Switch_3_In <= not i_Switch_3;

  Debounce_SW1 : entity work.Debounce_Filter
    generic map (DEBOUNCE_LIMIT => DEBOUNCE_LIMIT)
    port map (
      i_Clk       => i_Clk,
      i_Bouncy    => w_Switch_1_In,
      o_Debounced => w_Switch_1
    );

  Debounce_SW2 : entity work.Debounce_Filter
    generic map (DEBOUNCE_LIMIT => DEBOUNCE_LIMIT)
    port map (
      i_Clk       => i_Clk,
      i_Bouncy    => w_Switch_2_In,
      o_Debounced => w_Switch_2
    );

  Debounce_SW3 : entity work.Debounce_Filter
    generic map (DEBOUNCE_LIMIT => DEBOUNCE_LIMIT)
    port map (
      i_Clk       => i_Clk,
      i_Bouncy    => w_Switch_3_In,
      o_Debounced => w_Switch_3
    );

  Game_Inst : entity work.State_Machine_Game
    generic map (
      CLKS_PER_SEC => CLKS_PER_SEC,
      GAME_LIMIT   => GAME_LIMIT
    )
    port map (
      i_Clk      => i_Clk,
      i_Switch_1 => w_Switch_1,
      i_Switch_2 => w_Switch_2,
      i_Switch_3 => w_Switch_3,
      o_Score    => w_Score,
      o_LED_1    => o_LED_1,
      o_LED_2    => o_LED_2,
      o_LED_3    => o_LED_3
    );

  SevenSeg_Inst : entity work.Binary_To_7Segment
    port map (
      i_Clk        => i_Clk,
      i_Binary_Num => w_Score,
      o_Segment_A  => w_Seg_A,
      o_Segment_B  => w_Seg_B,
      o_Segment_C  => w_Seg_C,
      o_Segment_D  => w_Seg_D,
      o_Segment_E  => w_Seg_E,
      o_Segment_F  => w_Seg_F,
      o_Segment_G  => w_Seg_G
    );

  -- LED 7 đoạn trên ACG525 là Common Anode (0 = Sáng, 1 = Tắt)
  -- Thứ tự bit: DP, G, F, E, D, C, B, A
  w_Seg_Byte <= '1' & (not w_Seg_G) & (not w_Seg_F) & (not w_Seg_E) &
                      (not w_Seg_D) & (not w_Seg_C) & (not w_Seg_B) & (not w_Seg_A);

  -- Khung 16-bit gửi ra 2 tầng 74HC595:
  -- 8 bit cao (chọn thanh): w_Seg_Byte
  -- 8 bit thấp (chọn LED thứ nhất sáng): x"01"
  w_Shift_Reg <= w_Seg_Byte & x"01";

  -- Bộ điều khiển dịch 16-bit nối tiếp ra 74HC595
  process (i_Clk) is
  begin
    if rising_edge(i_Clk) then
      r_Clk_Div <= r_Clk_Div + 1;

      if r_Clk_Div = 0 then
        if r_Bit_Cnt < 16 then
          r_RCLK <= '0';
          r_SCLK <= '0';
          r_DIO  <= w_Shift_Reg(15 - r_Bit_Cnt);
        else
          r_SCLK <= '0';
          r_RCLK <= '1'; -- Chốt dữ liệu ra ngõ song song của 74HC595
        end if;
      elsif r_Clk_Div = 512 then
        if r_Bit_Cnt < 16 then
          r_SCLK    <= '1'; -- Cạnh lên dịch bit
          r_Bit_Cnt <= r_Bit_Cnt + 1;
        else
          r_RCLK    <= '0';
          r_Bit_Cnt <= 0;
        end if;
      end if;
    end if;
  end process;

  o_SEG7_DIO  <= r_DIO;
  o_SEG7_RCLK <= r_RCLK;
  o_SEG7_SCLK <= r_SCLK;

end architecture RTL;