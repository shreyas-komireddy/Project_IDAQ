---- LIBRARY DECLARATION
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

---- ENTITY DECLARATIOM
-- Generic Delay Generator
entity DLY_CTRLR is
  Port (
         clk_in  : in  std_logic;
         sys_rst : in  std_logic;
         en      : in  std_logic;
         dly_tme : in  unsigned(23 downto 0);
         done    : out std_logic
       );
end DLY_CTRLR;

--- DLY_CTRLR Module Behavior
architecture Behavioral of DLY_CTRLR is

signal dly_cntr : unsigned(23 downto 0) := (others => '0');
signal tme_rched : std_logic := '0';

begin

-- Delay counter process that asserts 'done' after 'dly_tme' cycles when 'en' is active.
DLY_PROCESS: process(clk_in)
begin
  if rising_edge(clk_in) then
     if sys_rst = '0' then
        done <= '0';
        tme_rched <= '0';
        dly_cntr <= (others => '0'); 
     else 
        if en = '1' then
           if tme_rched = '1' then
              done <= '1';
              dly_cntr <= (others => '0');
              tme_rched <= '0';
           else
              dly_cntr <= dly_cntr + 1;
              if dly_cntr = dly_tme then
                 tme_rched <= '1';
              end if;
           end if;
        else
           done <= '0';
        end if;
     end if;
 end if;
end process DLY_PROCESS;

end Behavioral;