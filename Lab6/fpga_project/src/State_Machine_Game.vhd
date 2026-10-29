library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity State_Machine_Game is
  generic (
    CLKS_PER_SEC : integer := 50000000;
    GAME_LIMIT   : integer := 7
  );
  port (
    i_Clk      : in  std_logic;
    i_Switch_1 : in  std_logic;
    i_Switch_2 : in  std_logic;
    i_Switch_3 : in  std_logic;
    o_Score    : out std_logic_vector(3 downto 0);
    o_LED_1    : out std_logic;
    o_LED_2    : out std_logic;
    o_LED_3    : out std_logic
  );
end entity State_Machine_Game;

architecture RTL of State_Machine_Game is

  type t_SM_Main is (START, PATTERN_OFF, PATTERN_SHOW,
                     WAIT_PLAYER, INCR_SCORE, LOSER, WINNER);
  signal r_SM_Main : t_SM_Main := START;

  signal w_Count_En, w_Toggle, r_Toggle, r_Switch_1, r_Switch_2, r_Switch_3, r_Button_DV : std_logic := '0';

  type t_Pattern is array (0 to 10) of std_logic_vector(1 downto 0);
  signal r_Pattern : t_Pattern := (others => (others => '0'));

  signal w_LFSR_Data : std_logic_vector(21 downto 0);
  signal r_Index     : integer range 0 to GAME_LIMIT := 0;
  signal w_Index_SLV : std_logic_vector(3 downto 0);
  signal r_Button_ID : std_logic_vector(1 downto 0) := (others => '0');
  signal r_Score     : unsigned(3 downto 0) := (others => '0');

begin

  process (i_Clk) is
  begin
    if rising_edge(i_Clk) then
      -- Reset trò chơi từ bất kỳ trạng thái nào khi nhấn đồng thời Switch 1 & Switch 2
      if i_Switch_1 = '1' and i_Switch_2 = '1' then
        r_SM_Main <= START;
      else
        case r_SM_Main is

          -- Giữ ở trạng thái START cho tới khi người chơi nhả 2 nút Reset ra
          when START =>
            if (i_Switch_1 = '0' and i_Switch_2 = '0' and r_Button_DV = '1') then
              r_Score   <= to_unsigned(0, r_Score'length);
              r_Index   <= 0;
              r_SM_Main <= PATTERN_OFF;
            end if;

          when PATTERN_OFF =>
            if w_Toggle = '0' and r_Toggle = '1' then -- Cạnh xuống của Toggle
              r_SM_Main <= PATTERN_SHOW;
            end if;

          when PATTERN_SHOW =>
            if w_Toggle = '0' and r_Toggle = '1' then -- Cạnh xuống của Toggle
              if r_Score = r_Index then
                r_Index   <= 0;
                r_SM_Main <= WAIT_PLAYER;
              else
                r_Index   <= r_Index + 1;
                r_SM_Main <= PATTERN_OFF;
              end if;
            end if;

          when WAIT_PLAYER =>
            if r_Button_DV = '1' then
              if (r_Pattern(r_Index) = r_Button_ID and unsigned(w_Index_SLV) = r_Score) then
                r_Index   <= 0;
                r_SM_Main <= INCR_SCORE;
              elsif r_Pattern(r_Index) /= r_Button_ID then
                r_SM_Main <= LOSER;
              else
                r_Index <= r_Index + 1;
              end if;
            end if;

          when INCR_SCORE =>
            r_Score <= r_Score + 1;
            if r_Score = GAME_LIMIT - 1 then
              r_SM_Main <= WINNER;
            else
              r_SM_Main <= PATTERN_OFF;
            end if;

          -- Hiển thị 0xA (Chữ A) khi chiến thắng
          when WINNER =>
            r_Score <= "1010";

          -- Hiển thị 0xF (Chữ F) khi thua cuộc
          when LOSER =>
            r_Score <= "1111";

          when others =>
            r_SM_Main <= START;
        end case;
      end if;
    end if;
  end process;

  w_Index_SLV <= std_logic_vector(to_unsigned(r_Index, w_Index_SLV'length));

  -- Nạp chuỗi ngẫu nhiên từ LFSR vào mảng r_Pattern khi đang ở trạng thái START
  -- Vì chỉ dùng 3 LED (00, 01, 10), nếu LFSR ra "11" thì quy về "00" (LED 1)
  process (i_Clk) is
    variable v_pair : std_logic_vector(1 downto 0);
  begin
    if rising_edge(i_Clk) then
      if r_SM_Main = START then
        for i in 0 to 10 loop
          v_pair := w_LFSR_Data(i*2 + 1 downto i*2);
          if v_pair = "11" then
            r_Pattern(i) <= "00";
          else
            r_Pattern(i) <= v_pair;
          end if;
        end loop;
      end if;
    end if;
  end process;

  -- Điều khiển 3 LED hiển thị mẫu hoặc sáng theo nút người chơi bấm
  o_LED_1 <= '1' when (r_SM_Main = PATTERN_SHOW and r_Pattern(r_Index) = "00") else '0';
  o_LED_2 <= '1' when (r_SM_Main = PATTERN_SHOW and r_Pattern(r_Index) = "01") else '0';
  o_LED_3 <= '1' when (r_SM_Main = PATTERN_SHOW and r_Pattern(r_Index) = "10") else '0';

  -- Phát hiện cạnh xuống của nút nhấn (nhả nút)
  process (i_Clk) is
  begin
    if rising_edge(i_Clk) then
      r_Toggle   <= w_Toggle;
      r_Switch_1 <= i_Switch_1;
      r_Switch_2 <= i_Switch_2;
      r_Switch_3 <= i_Switch_3;

      if r_Switch_1 = '1' and i_Switch_1 = '0' then
        r_Button_DV <= '1';
        r_Button_ID <= "00";
      elsif r_Switch_2 = '1' and i_Switch_2 = '0' then
        r_Button_DV <= '1';
        r_Button_ID <= "01";
      elsif r_Switch_3 = '1' and i_Switch_3 = '0' then
        r_Button_DV <= '1';
        r_Button_ID <= "10";
      else
        r_Button_DV <= '0';
        r_Button_ID <= "00";
      end if;
    end if;
  end process;

  w_Count_En <= '1' when (r_SM_Main = PATTERN_SHOW or r_SM_Main = PATTERN_OFF) else '0';

  Count_Inst : entity work.Count_And_Toggle
    generic map (
      COUNT_LIMIT => CLKS_PER_SEC / 4
    )
    port map (
      i_Clk    => i_Clk,
      i_Enable => w_Count_En,
      o_Toggle => w_Toggle
    );

  LFSR_Inst : entity work.LFSR_22
    port map (
      i_Clk       => i_Clk,
      o_LFSR_Data => w_LFSR_Data,
      o_LFSR_Done => open
    );

  o_Score <= std_logic_vector(r_Score);

end architecture RTL;