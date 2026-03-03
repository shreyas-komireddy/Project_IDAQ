---- LIBRARY DECLARATION
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

---- ENTITY DECLARATION
-- Performs acquisition of ADC samples through the SPI interface.
-- Reads channel information + ADC data, classifies it to output registers,
-- and scan variable input type modes using config_dta(4 downto 3).
entity AD7328_ACQ is
  PORT ( 
         clk_in       : in  std_logic;
         sys_rst      : in  std_logic;
         en           : in  std_logic;                              -- Enable Acquisition sequence 
         done         : out std_logic;                              -- Acquisition completion flag
         bit_num      : in  unsigned(4 downto 0);
         acq_cs       : out std_logic;
         acq_sclk     : out std_logic;
         acq_sdo      : in  std_logic;
         ctrlr_reg    : in  std_logic_vector(7 downto 0);           -- Only (4 downto 3) are decoded to determine the AD7328_ACQ logic
         config_dta   : in  std_logic_vector(31 downto 0);          -- Only (4 downto 3) are decoded to determine  the AD7328_ACQ logic
         out_regA     : out std_logic_vector(31 downto 0);
         out_regB     : out std_logic_vector(31 downto 0);
         out_regC     : out std_logic_vector(31 downto 0);
         out_regD     : out std_logic_vector(31 downto 0);
         tst_reg      : out std_logic_vector(15 downto 0)
       );
end AD7328_ACQ;

---- AD7328_ACQ Module Architecture
architecture Behavioral of AD7328_ACQ is

--- Instantiation of the SPI Interface Module
-- AD7328_ACQ uses rd_sdo='1' to place SPI in read-from-ADC mode.
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
         rd_sdo    : in  std_logic;  
         bit_num   : in  unsigned(4 downto 0);
         ctrlr_reg : in  std_logic_vector(7 downto 0);            -- Only (7 downto 0) are decoded to control the SPI_INTRFC logic
         dta_in    : in  std_logic_vector(15 downto 0);
         dta_out   : out std_logic_vector(15 downto 0)    
      );  
end component;

--- Acquisition State Machine Definition
-- The FSM enables the SPI block to acquire the data and store.
type state_type is (IDLE, ACQ_DTA, CHANL_DTA, FINISH);
signal acq_state: state_type := IDLE;

-- Internal Signals for SPI Interface
signal spi_en        : std_logic;
signal spi_done      : std_logic;
signal spi_dta_out   : std_logic_vector(15 downto 0);
signal spi_rd_sdo    : std_logic;
signal dummy_dta_in  : std_logic_vector(15 downto 0);

signal chnl_cnt      : unsigned(3 downto 0) := "0000";        ----- No.of Channels processed based on Input Type mode -----
signal chnl_num      : std_logic_vector(2 downto 0);          -----      Extracted from ADC outdata (bits 15:13)      -----

type array_type is array (0 to 7) of std_logic_vector(15 downto 0);
signal chnl_dta : array_type;                                 ----- Temporary 13-bit storage for each of 8 ADC channels -----

begin

--- SPI Interface Instantiation
INTRFC_CTRL: SPI_INTRFC
 Port Map (
            clk_in    => clk_in,
            sys_rst   => sys_rst,
            en        => spi_en,
            done      => spi_done,
            cs        => acq_cs,
            sclk      => acq_sclk,
            sdi       => open,                     -- sdi unused
            sdo       => acq_sdo,
            rd_sdo    => spi_rd_sdo,
            bit_num   => bit_num,
            ctrlr_reg => ctrlr_reg,
            dta_in    => dummy_dta_in,            -- dta_in unused
            dta_out   => spi_dta_out
          );

--- Captures 13-bit ADC data at an user-controlled instance
CAPTURE_DTA: process(clk_in)
begin
 if rising_edge(clk_in) then
  if ctrlr_reg(4 downto 3) = "11" then 
     out_regA(15 downto 0)  <= chnl_dta(0);      ----- REG_A ==> Channel 0 & Channel 1 Data -----  
     out_regA(31 downto 16) <= chnl_dta(1);       
     out_regB(15 downto 0)  <= chnl_dta(2);      ----- REG_B ==> Channel 2 & Channel 3 Data -----  
     out_regB(31 downto 16) <= chnl_dta(3);
     out_regC(15 downto 0)  <= chnl_dta(4);      ----- REG_C ==> Channel 5 & Channel 5 Data -----  
     out_regC(31 downto 16) <= chnl_dta(5);
     out_regD(15 downto 0)  <= chnl_dta(6);      ----- REG_D ==> Channel 6 & Channel 7 Data -----  
     out_regD(31 downto 16) <= chnl_dta(7);
  end if;
 end if;
end process;

--- Main Acquisition Process
-- Controls SPI read sequence, channels cycle and completion flag.
ACQ_PROCESS: process(clk_in)
begin
  if rising_edge(clk_in) then
     if sys_rst = '0' then   
        done <= '0';
        spi_en <= '0';
        spi_rd_sdo <= '0';
        acq_state <= IDLE;
        tst_reg <= x"0000";
     else
        case acq_state is
      
         -- IDLE: Wait for 'en' to start acquisition
          when IDLE =>
            if en = '1' then 
               acq_state <= ACQ_DTA;
               spi_rd_sdo <= '1';
            elsif en = '0' then
               done <= '0';
               spi_en <= '0';
               spi_rd_sdo <= '0';
            end if;
          
         -- ACQ_DTA: Start SPI read, wait for 16-bit frame  
          when ACQ_DTA =>
            spi_en <= '1';
            if spi_done = '1' then
               chnl_num <= spi_dta_out(15 downto 13);    -- Extract Channel ID
               --tst_reg <= spi_dta_out(15 downto 0);
               spi_en <= '0';
               acq_state <= CHANL_DTA;
            end if;
          
         -- CHANL_DTA: Store data in the correct channel slot  
          when CHANL_DTA =>
            chnl_dta(to_integer(unsigned(chnl_num))) <= spi_dta_out(15 downto 0);
            case config_dta(4 downto 3) is
          
             -- Full 8-channel scan as Single-Ended Input type mode
              when "00" =>
                if chnl_cnt < 7 then
                   chnl_cnt <= chnl_cnt + 1;
                   acq_state <= ACQ_DTA;
                else
                   chnl_cnt <= "0000";
                   acq_state <= FINISH;  
                end if;
         
             -- 4-channel scan as True Differential or Psuedo Differential Input type mode
              when "10" | "01" =>
                if chnl_cnt < 3 then
                   chnl_cnt <= chnl_cnt + 1;
                   acq_state <= ACQ_DTA;
                else
                   chnl_cnt <= "0000";
                   acq_state <= FINISH;   
                end if;
         
             -- 7-channel scan as Pseudo Differential Input type mode    
              when "11" => 
                if chnl_cnt < 6 then
                   chnl_cnt <= chnl_cnt + 1;
                   acq_state <= ACQ_DTA;
                else 
                   chnl_cnt <= "0000";
                   acq_state <= FINISH;  
                end if;
                
             -- Safety Fallback State
              when others =>
                chnl_cnt <= "0000";
                acq_state <= FINISH;
            end case;
    
        -- FINISH: Assert done, wait for deassert of enable      
         when FINISH =>
           done <= '1';
           if en = '0' then
              acq_state <= IDLE;
              done <= '0';
              spi_rd_sdo <= '0';
           end if;
           
        -- Safety Fallback State
         when others =>
           acq_state <= IDLE; 
                             
       end case;
     end if;
  end if;
 end process;        
end Behavioral;
