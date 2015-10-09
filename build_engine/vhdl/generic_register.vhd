library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity generic_register is
   generic (
      DATA_WIDTH                 : natural   := 32
   );
   port (
      clk                        : in std_logic;
      rst                        : in std_logic;
      data_in                    : in std_logic_vector(DATA_WIDTH-1 downto 0);
      data_out                   : out std_logic_vector(DATA_WIDTH-1 downto 0)
   );
end generic_register;

architecture Behavioral of generic_register is

begin

   process (clk)
   begin
      if rising_edge(clk) then
         if rst = '1' then
            data_out <= (others => '0');
         else
            data_out <= data_in;
         end if;
      end if;
   end process;


end Behavioral;

