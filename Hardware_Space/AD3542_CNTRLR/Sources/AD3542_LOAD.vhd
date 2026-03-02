---- LIBRARY DECLARATION
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

---- ENTITY DECLARATION
entity AD3542_LOAD is
  Port ( 
         clk_in    : in  std_logic;
         sys_rst   : in  std_logic;
         en        : in  std_logic;                           -- Enable Load
         done      : out std_logic;                           -- Load Completion Flag
         dac_ldac  : out std_logic;                           -- DAC LDAC pin
         load_cs   : out std_logic; 
         load_sclk : out std_logic;
         load_sdi  : out std_logic;
         strm_on   : in  std_logic;
         ctrlr_reg : in  std_logic_vector(7 downto 0);
         ch1_dta   : in  std_logic_vector(15 downto 0);       -- DAC CH1 Data          
         ch0_dta   : in  std_logic_vector(15 downto 0)        -- DAC CH0 Data
       );
end AD3542_LOAD;

---- AD3542_LOAD Module Architecture
architecture Behavioral of AD3542_LOAD is

-- SPI interface module
component SPI_INTRFC is
 Port (  
         clk_in    : in  std_logic;
         sys_rst   : in  std_logic;
         en        : in  std_logic;
         done      : out std_logic;
         cs        : out std_logic;
         sclk      : out std_logic; 
         sdi       : out std_logic;
         sdo       : in  std_logic;
         strm_on   : in  std_logic;
         bit_flg   : out std_logic;
         bit_num   : in  unsigned(4 downto 0);
         ctrlr_reg : in  std_logic_vector(7 downto 0);             -- Only (7 downto 0) are decoded to control the SPI_INTRFC logic
         dta_in    : in  std_logic_vector(31 downto 0)  
      );  
end component;

-- Delay generator
component DLY_CTRLR is
 Port (
         clk_in  : in  std_logic;
         sys_rst : in  std_logic;
         en      : in  std_logic;
         done    : out std_logic;
         dly_tme : in  unsigned(23 downto 0)
       );
end component;

--- Load State Machine Definition
-- The FSM enables the SPI block to load the data.
 type state is (IDLE, LOAD_CH1, LOAD_CH0, LDAC, FINISH);
 signal load_state : state := IDLE; 

  --- SPI_INTRFC Module Internal Signals
 signal spi_en        : std_logic := '0';
 signal spi_done      : std_logic := '0';
 signal bit_flg       : std_logic ;
 signal bit_num       : unsigned(4 downto 0) := "11111";
 signal dta_in        : std_logic_vector(31 downto 0);
 signal dummy_sdo     : std_logic;
 signal dummy_rd_sdo  : std_logic;

 
 --- DLY_MODULE Module Internal Signals
 signal dly_en   : std_logic := '0';
 signal dly_done : std_logic := '0';
 signal dly_tme  : unsigned(23 downto 0) := x"000000"; 
 
begin

--- SPI Interface Instantiation
INTRFC_CTRL: SPI_INTRFC
 Port Map (
            clk_in        => clk_in,
            sys_rst       => sys_rst,
            en            => spi_en,
            done          => spi_done,
            cs            => load_cs,
            sclk          => load_sclk,
            sdi           => load_sdi,
            sdo           => dummy_sdo,
            strm_on       => strm_on,
            bit_flg       => bit_flg,
            bit_num       => bit_num,
            ctrlr_reg     => ctrlr_reg,
            dta_in        => dta_in
          );

-- Delay Controller Instantiation
 DELAY_CTRL: DLY_CTRLR
  Port Map (
             clk_in  => clk_in,
             sys_rst => sys_rst,
             en      => dly_en,
             done    => dly_done,
             dly_tme => dly_tme
           );

-- Main Load Process 
-- Controls DAC input loading sequence and completion flag.
 LOAD_PROCESS: process(clk_in)
 begin
   if rising_edge(clk_in) then
      if sys_rst = '0' then
         spi_en  <= '0';
         dly_en  <= '0'; 
         dac_ldac <= '1';
         done <= '0';
         bit_num <= "11111";
         dly_tme <= x"000000";
         load_state <= IDLE;
      else
         case load_state is
         
          -- IDLE: Wait for 'en' to start a new DAC load cycle
            when IDLE =>
              if en = '1' then     
                 dac_ldac <= '1';   
                 dly_tme <= x"000000";         
                 load_state <= LOAD_CH1;
                 dta_in <= x"4B" & ch1_dta & x"00"; 
              elsif en = '0' then
                 spi_en <= '0';
                 dly_en  <= '0';
                 done <= '0';
                 bit_num <= "11111";
              end if;
      
          -- LOAD_CH1: Start SPI transfer for Channel 1 data
            when LOAD_CH1 =>
              spi_en <= '1';
              if bit_flg = '1' then                    -- Indicates transition to next CH Data
                 load_state <= LOAD_CH0;
                 --bit_num <= "10111";
                 dta_in <= x"48" & ch0_dta & x"00";
              end if;
           
          -- LOAD_CH0: After CH1, now send CH0 to DAC  
            when LOAD_CH0 =>
              if spi_done = '1' then
                 spi_en <= '0';
                 bit_num <= "11111";                  -- Reset Bit Number
                 dly_tme <= x"000006";                -- LDAC Delay
                 load_state <= LDAC;
              end if;
       
          -- LDAC: Pulse DAC_LDAC low to latch CH0 + CH1 data together    
            when LDAC =>
              dly_en <= '1';
              dac_ldac <= '0';                      -- LDAC Active Low
              if dly_done = '1' then                -- Delay Finished
                 dly_en <= '0';
                 dac_ldac <= '1';                   -- Release LDAC
                 load_state <= FINISH;
              end if;
            
          -- FINISH: Assert done, wait for deassert of enable    
            when FINISH =>
            done <= '1';                                                      -- LOADComplete
            if en = '0' then
               done <= '0'; 
               load_state <= IDLE;                     
            end if;
      
          -- Safety Fallback  
           when others =>
             load_state <= IDLE;
         end case;     
    end if; 
  end if;    
end process LOAD_PROCESS;
end Behavioral;
