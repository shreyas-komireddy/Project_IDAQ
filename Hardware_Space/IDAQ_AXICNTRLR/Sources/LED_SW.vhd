
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity LED_SW is
    Port ( 
           sw_in     :  in std_logic;
           led_out   : out std_logic_vector(7 downto 0);
           rtcc_in   : in  std_logic_vector(7 downto 0);
           intr_pltf : in  std_logic_vector(7 downto 0)
         );
end LED_SW;

architecture Behavioral of LED_SW is

begin
 
 led_out <= intr_pltf when sw_in = '1' else rtcc_in;


end Behavioral;
