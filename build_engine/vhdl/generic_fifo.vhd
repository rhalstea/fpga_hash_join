library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Fall Through FIFO
entity generic_fifo is
   generic (
      DATA_WIDTH                 : natural      := 8;
      DATA_DEPTH                 : natural      := 32;
      AFULL_POS                  : natural      := 24
   );
   port (
      clk                        : in std_logic;
      rst                        : in std_logic;
      
      afull_out                  : out std_logic;
      write_en_in                : in std_logic;
      data_in                    : in std_logic_vector(DATA_WIDTH-1 downto 0);
      
      empty_out                  : out std_logic;
      read_en_in                 : in std_logic;
      data_out                   : out std_logic_vector(DATA_WIDTH-1 downto 0)
   );
end generic_fifo;

architecture Behavioral of generic_fifo is
   type FIFO_T is array (DATA_DEPTH-1 downto 0) of std_logic_vector(DATA_WIDTH-1 downto 0);
   
   signal memory_s               : FIFO_T;
   signal push_pointer_s         : natural;
   signal pop_pointer_s          : natural;

   signal afull_s                : std_logic;
   signal empty_s                : std_logic;

begin

   -- Push element onto the FIFO
   process (clk)
   begin
      if rising_edge(clk) then
         if rst = '1' then
            push_pointer_s    <= 0;
            
         elsif write_en_in = '1' then
            memory_s(push_pointer_s) <= data_in;
            
            if push_pointer_s >= DATA_DEPTH-1 then
               push_pointer_s <= 0;
            else
               push_pointer_s <= push_pointer_s + 1;
            end if;
            
         end if;
      end if;
   end process;

   -- Pop element from the FIFO
   process (clk)
   begin
      if rising_edge(clk) then
         if rst = '1' then
            pop_pointer_s <= 0;
            
         elsif read_en_in = '1' and empty_s = '0' then
            if pop_pointer_s >= DATA_DEPTH-1 then
               pop_pointer_s <= 0;
            else
               pop_pointer_s <= pop_pointer_s + 1;
            end if;
         end if;
      end if;
   end process;
   
   empty_s  <= '1'   when  push_pointer_s = pop_pointer_s else '0';
   afull_s  <= '1'   when  ((push_pointer_s > pop_pointer_s) and (push_pointer_s - pop_pointer_s > AFULL_POS)) or
                           ((push_pointer_s < pop_pointer_s) and (DATA_DEPTH-1 - pop_pointer_s + push_pointer_s > AFULL_POS))
                     else  '0';
   
   empty_out   <= empty_s;
   afull_out   <= afull_s;
   data_out    <= memory_s(pop_pointer_s);
   
end Behavioral;
