library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Count_And_Toggle is
  generic (
    COUNT_LIMIT : natural := 12500000
  );
  port (
    i_Clk    : in  std_logic;
    i_Enable : in  std_logic;
    o_Toggle : out std_logic
  );
end entity Count_And_Toggle;

architecture RTL of Count_And_Toggle is
  signal r_Counter : natural range 0 to COUNT_LIMIT - 1 := 0;
  signal r_Toggle  : std_logic := '0';
begin
  process (i_Clk) is
  begin
    if rising_edge(i_Clk) then
      if i_Enable = '1' then
        if r_Counter = COUNT_LIMIT - 1 then
          r_Toggle  <= not r_Toggle;
          r_Counter <= 0;
        else
          r_Counter <= r_Counter + 1;
        end if;
      else
        r_Toggle  <= '0';
        r_Counter <= 0;
      end if;
    end if;
  end process;

  o_Toggle <= r_Toggle;
end architecture RTL;