library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Binary_To_7Segment is
  port (
    i_Clk        : in  std_logic;
    i_Binary_Num : in  std_logic_vector(3 downto 0);
    o_Segment_A  : out std_logic;
    o_Segment_B  : out std_logic;
    o_Segment_C  : out std_logic;
    o_Segment_D  : out std_logic;
    o_Segment_E  : out std_logic;
    o_Segment_F  : out std_logic;
    o_Segment_G  : out std_logic
  );
end entity Binary_To_7Segment;

architecture RTL of Binary_To_7Segment is
  signal r_Hex_Encoding : std_logic_vector(6 downto 0) := (others => '0');
begin
  process (i_Clk) is
  begin
    if rising_edge(i_Clk) then
      case i_Binary_Num is
        when "0000" => r_Hex_Encoding <= "1111110"; -- 0
        when "0001" => r_Hex_Encoding <= "0110000"; -- 1
        when "0010" => r_Hex_Encoding <= "1101101"; -- 2
        when "0011" => r_Hex_Encoding <= "1111001"; -- 3
        when "0100" => r_Hex_Encoding <= "0110011"; -- 4
        when "0101" => r_Hex_Encoding <= "1011011"; -- 5
        when "0110" => r_Hex_Encoding <= "1011111"; -- 6
        when "0111" => r_Hex_Encoding <= "1110000"; -- 7
        when "1000" => r_Hex_Encoding <= "1111111"; -- 8
        when "1001" => r_Hex_Encoding <= "1111011"; -- 9
        when "1010" => r_Hex_Encoding <= "1110111"; -- A (Thắng)
        when "1011" => r_Hex_Encoding <= "0011111"; -- b
        when "1100" => r_Hex_Encoding <= "1001110"; -- C
        when "1101" => r_Hex_Encoding <= "0111101"; -- d
        when "1110" => r_Hex_Encoding <= "1001111"; -- E
        when "1111" => r_Hex_Encoding <= "1000111"; -- F (Thua)
        when others => r_Hex_Encoding <= "0000000";
      end case;
    end if;
  end process;

  o_Segment_A <= r_Hex_Encoding(6);
  o_Segment_B <= r_Hex_Encoding(5);
  o_Segment_C <= r_Hex_Encoding(4);
  o_Segment_D <= r_Hex_Encoding(3);
  o_Segment_E <= r_Hex_Encoding(2);
  o_Segment_F <= r_Hex_Encoding(1);
  o_Segment_G <= r_Hex_Encoding(0);
end architecture RTL;