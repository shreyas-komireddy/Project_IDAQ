---- LIBRARY DECLARATION
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

---- ENTITY DECLARATION
-- AD3542 configuration controller
-- Handles reset, delays and SPI register writes
entity AD3542_CONFIG is
   Port ( 
          clk_in         : in  std_logic;
          sys_rst        : in  std_logic;
          en             : in  std_logic;                           -- Enable Config
          done           : out std_logic;                           -- Config Completion Flag
          dac_rst        : out std_logic_vector(3 downto 0);                           -- DAC reset pin
          config_cs      : out std_logic_vector(3 downto 0);
          config_sclk    : out std_logic_vector(3 downto 0);
          config_sdi     : out std_logic_vector(3 downto 0);
          strm_on        : in  std_logic;
          ctrlr_reg      : in  std_logic_vector(7 downto 0);
          config_dta     : in  std_logic_vector(31 downto 0)        -- User config data
        );
end AD3542_CONFIG;

---- AD3542_CONFIG Module Architecture
architecture Behavioral of AD3542_CONFIG is

-- SPI Interface (tx-only for AD3542 writes)
component SPI_INTRFC is
 Port (  
         clk_in    : in  std_logic;
         sys_rst   : in  std_logic;
         en        : in  std_logic;
         done      : out std_logic;
         cs        : out std_logic_vector(3 downto 0);
         sclk      : out std_logic_vector(3 downto 0);
         sdi       : out std_logic_vector(3 downto 0);
         sdo       : in  std_logic_vector(3 downto 0);   
         strm_on   : in  std_logic;
         bit_flg   : out std_logic;
         bit_num   : in  unsigned(4 downto 0);
         ctrlr_reg : in  std_logic_vector(7 downto 0);             -- Only (7 downto 0) are decoded to control the SPI_INTRFC logic
         dac1_dta  : in  std_logic_vector(31 downto 0);    
         dac2_dta  : in  std_logic_vector(31 downto 0);
         dac3_dta  : in  std_logic_vector(31 downto 0);
         dac4_dta  : in  std_logic_vector(31 downto 0)
      );  
end component;

-- Delay controller for reset/hold timings
component DLY_CTRLR is
 Port (
         clk_in  : in  std_logic;
         sys_rst : in  std_logic;
         en      : in  std_logic;
         done    : out std_logic;
         dly_tme : in  unsigned(23 downto 0)
       );
end component;

--- State Machine Holds the active state of the SPI interface controller.
-- Controls the Intialisation and Configuration Sequence
 type state is (IDLE, HRD_RST, HOLD, WRT_REGB, WRT_PWRDWN, WRT_VREF, WRT_OUTRANGE,
                WRT_REGA, WRT_BYTELNGTH, WRT_BYTEVAL, WRT_REGB_STRM, FINISH);
 signal config_state : state := IDLE;
 
  --- SPI_INTRFC Module Internal Signals
 signal spi_en        : std_logic := '0';
 signal spi_done      : std_logic := '0';
 signal bit_num       : unsigned(4 downto 0) := "01111";
 signal dac1_dta      : std_logic_vector(31 downto 0);
 signal dac2_dta      : std_logic_vector(31 downto 0);
 signal dac3_dta      : std_logic_vector(31 downto 0);
 signal dac4_dta      : std_logic_vector(31 downto 0);
 signal dummy_sdo     : std_logic_vector(3 downto 0);

 
 --- DLY_MODULE Module Internal Signals
 signal dly_en   : std_logic := '0';
 signal dly_done : std_logic := '0';
 signal dly_tme  : unsigned(23 downto 0) := x"000008"; 
 
begin

INTRFC_CTRL: SPI_INTRFC
 Port Map (
            clk_in        => clk_in,
            sys_rst       => sys_rst,
            en            => spi_en,
            done          => spi_done,
            cs            => config_cs,
            sclk          => config_sclk,
            sdi           => config_sdi,
            sdo           => dummy_sdo,
            strm_on       => strm_on,
            bit_flg       => open,
            bit_num       => bit_num,
            ctrlr_reg     => ctrlr_reg,
            dac1_dta      => dac1_dta,
            dac2_dta      => dac2_dta,
            dac3_dta      => dac3_dta,
            dac4_dta      => dac4_dta
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

 -- FSM-based process managing DAC reset, delays, and Configuration transactions.
 CONFIG_PROCESS: process(clk_in)
 begin
   if rising_edge(clk_in) then
      if sys_rst = '0' then
         spi_en  <= '0';
         dly_en  <= '0'; 
         dac_rst <= "1111";
         done <= '0';
         bit_num <= "01111";
         dly_tme <= x"000008";
         config_state <= IDLE;
      else
         case config_state is
         
          -- IDLE: Wait for 'en' to start the configuration sequence
           when IDLE =>
             if en = '1' then
                dac_rst <= "1111";
                dly_tme <= x"000008"; 
                config_state <= HRD_RST;
             elsif en = '0' then 
                done <= '0';
                spi_en <= '0';
                dly_en  <= '0';   
                bit_num <= "01111";     
             end if;
       
          -- HRD_RST: Drive DAC reset low for required time
           when HRD_RST =>
             dly_en <= '1';
             dac_rst <= "0000";
             if dly_done = '1' then
                dly_en <= '0';
                dly_tme <= x"BEBC2A"; 
                config_state <= HOLD;
             end if;
      
          -- HOLD: Release DAC reset and wait for power-up stabilization
           when HOLD =>
            dly_en <= '1';
            dac_rst <= "1111";
            if dly_done = '1' and dly_en /= '0' then
               dly_en <= '0';
               config_state <= WRT_REGB;
               dac1_dta <= x"00000188";
               dac2_dta <= x"00000188";
               dac3_dta <= x"00000188";
               dac4_dta <= x"00000188";
            end if;
     
          -- WRT_REGB: Write INTERFACE_CONFIG_B (mode register)
           when WRT_REGB =>
            spi_en <= '1';
            if spi_done = '1' then
               spi_en <= '0';
               config_state <= WRT_PWRDWN;
               dac1_dta <= x"000018" & "00" & config_dta(13 downto 12) & "00" & config_dta(9 downto 8); 
               dac2_dta <= x"000018" & "00" & config_dta(13 downto 12) & "00" & config_dta(9 downto 8);
               dac3_dta <= x"000018" & "00" & config_dta(13 downto 12) & "00" & config_dta(9 downto 8);
               dac4_dta <= x"000018" & "00" & config_dta(13 downto 12) & "00" & config_dta(9 downto 8);
            end if;
     
          -- WRT_PWRDWN: Write Power-down register  
           when WRT_PWRDWN =>
            spi_en <= '1';
            if spi_done = '1' and spi_en /= '0' then
               spi_en <= '0';
               config_state <= WRT_VREF;
               dac1_dta <= x"00001500";
               dac2_dta <= x"00001500";
               dac3_dta <= x"00001500";
               dac4_dta <= x"00001500";
            end if;
     
          -- WRT_VREF: Internal reference configuration
           when WRT_VREF =>
            spi_en <= '1';
            if spi_done = '1' and spi_en /= '0' then
               spi_en <= '0';
               config_state <= WRT_OUTRANGE;
               dac1_dta <= x"000019" & ctrlr_reg(5 downto 2) & ctrlr_reg(5 downto 2);
               dac2_dta <= x"000019" & ctrlr_reg(5 downto 2) & ctrlr_reg(5 downto 2);
               dac3_dta <= x"000019" & ctrlr_reg(5 downto 2) & ctrlr_reg(5 downto 2);
               dac4_dta <= x"000019" & ctrlr_reg(5 downto 2) & ctrlr_reg(5 downto 2);
               --dta_in <= x"000019" & '0' & config_dta(6 downto 4) & '0' & config_dta(2 downto 0);
            end if;
     
          -- WRT_OUTRANGE: Output range configuration  
           when WRT_OUTRANGE =>
            spi_en <= '1';
            if spi_done = '1' and spi_en /= '0' then
               spi_en <= '0';
               config_state <= WRT_REGA;
               dac1_dta <= x"00000010";
               dac2_dta <= x"00000010";
               dac3_dta <= x"00000010";
               dac4_dta <= x"00000010";
            end if;
     
          -- WRT_REGA: Sequential writes for multi-byte register programming
           when WRT_REGA =>
            spi_en <= '1';
            if spi_done = '1' and spi_en /= '0' then
               spi_en <= '0';
               config_state <= WRT_BYTELNGTH;
               dac1_dta <= x"00000E06";
               dac2_dta <= x"00000E06";
               dac3_dta <= x"00000E06";    
               dac4_dta <= x"00000E06";                                        -- Stream Length
            end if;
     
         -- WRT_BYTELNGTH: Number of Bytes defined for a frame 
           when WRT_BYTELNGTH =>
            spi_en <= '1';
            if spi_done = '1' and spi_en /= '0' then
               spi_en <= '0';
               config_state <= WRT_BYTEVAL;                                 
               dac1_dta <= x"00000F04";
               dac2_dta <= x"00000F04";
               dac3_dta <= x"00000F04";
               dac4_dta <= x"00000F04";                                           -- Byte Length Value Set Bit                                    
            end if;
       
         -- WRT_BYTEVAL: Defining the sate of previous Byte Length value
          when WRT_BYTEVAL =>
           spi_en <= '1';
           if spi_done = '1' and spi_en /= '0' then
              spi_en <= '0';
              config_state <= WRT_REGB_STRM;
              dac1_dta <= x"00000108";   
              dac2_dta <= x"00000108";
              dac3_dta <= x"00000108";
              dac4_dta <= x"00000108";                                          -- Streaming Mode
           end if;
         
         -- WRT_REGB_STRM: Streaming Mode ON
          when WRT_REGB_STRM =>
           spi_en <= '1';
           if spi_done = '1' and spi_en /= '0' then
              spi_en <= '0';
              config_state <= FINISH;                   
           end if;
            
         -- FINISH: Assert done, wait for deassert of enable    
          when FINISH =>
           done <= '1';                                                      -- CONFIG Complete
           if en = '0' then
              done <= '0';
              config_state <= IDLE;                     
           end if;
         
         --Safety Fallback State
          when others =>
            config_state <= IDLE;
        end case;
   end if;
  end if;
 end process CONFIG_PROCESS;      
end Behavioral;
