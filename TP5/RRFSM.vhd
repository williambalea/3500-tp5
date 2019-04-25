----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/29/2018 09:35:28 PM
-- Design Name: 
-- Module Name: RRFSM - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity RRFSM is
    Generic (
    DATA_WIDTH : integer	:= 8
    );
    Port (
    clk_RRFSM, reset : in std_logic;
    rx_dataFSM : in std_logic_vector(DATA_WIDTH - 1 downto 0);
    rx_dataFSM_valid : in std_logic;
    rx_busy : in std_logic;
    
    tx_dataFSM : out std_logic_vector(DATA_WIDTH - 1 downto 0);
    tx_dataFSM_valid : out std_logic;
    
    request_type_rx : out std_logic_vector (15 downto 0);
    request_en : out std_logic := '0';
    unpause : out std_logic := '0';
    
    request_type_tx : in std_logic_vector(7 downto 0);
    request_value : in std_logic_vector (31 downto 0);
    request_valid : in std_logic
    );
    

end RRFSM;


architecture Behavioral of RRFSM is

type etat_UR is (LECTURE, 
                 REQUETE_F, REQUETE_F_ATTENTE, 
                 REQUETE_R, REQUETE_R_ATTENTE, 
                 REQUETE_P,REQUETE_P_ATTENTE, 
                 REQUETE_M, REQUETE_M_ATTENTE, 
                 REPONSE, REPONSE_TYPE, REPONSE_8, REPONSE_16, REPONSE_24, REPONSE_32);
                 
signal stateUR : etat_UR := LECTURE;
begin

process (clk_RRFSM, reset) is
variable donnee : std_logic_vector ( 15 downto 0);
variable donneeMemoire : std_logic_vector (31 downto 0);
begin 

    if(reset = '1') then 
        stateUR <= LECTURE;
      elsif (rising_edge(clk_RRFSM)) then
        
    case stateUR is
    
    when LECTURE =>
    if ( rx_dataFSM_valid = '1') then
        donnee (7 downto 0) := rx_dataFSM;
        if ( donnee( 1 downto 0) = "11") then
            stateUR <= REQUETE_M;
        elsif (donnee( 1 downto 0) = "10") then
            stateUR <= REQUETE_F;
        elsif (donnee( 1 downto 0) = "01") then
            stateUR <= REQUETE_R;
        elsif (donnee( 1 downto 0) = "00") then
            stateUR <= REQUETE_P;
        end if;
    elsif (rx_dataFSM_valid = '0') then
        stateUR <= LECTURE;
    end if;
        
    when REQUETE_M =>
    if ( rx_dataFSM_valid = '1') then
        donnee (15 downto 8):= rx_dataFSM; 
        request_en <= '1';
        request_type_rx <= donnee;
        stateUR <= REQUETE_M_ATTENTE;
    elsif ( rx_dataFSM_valid = '0') then
        stateUR <= REQUETE_M;
    end if;
     
    when REQUETE_M_ATTENTE =>
    if (request_valid = '0') then
        stateUR <= REQUETE_M_ATTENTE;
    elsif (request_valid = '1') then       
        donneeMemoire := request_value;
        stateUR <= REPONSE;
    end if;

    when REQUETE_F =>
    request_en <= '1';
    request_type_rx <= donnee;
    stateUR <= REQUETE_F_ATTENTE;

    when REQUETE_F_ATTENTE =>
    request_en <= '0';
     if (request_valid = '0') then
        stateUR <= REQUETE_F_ATTENTE;
     elsif (request_valid = '1') then       
        donnee := request_value (7 downto 0);
        stateUR <= REPONSE;
     end if;
     
    when REQUETE_R =>
    request_en <= '1';
    request_type_rx <= donnee;
    stateUR <= REQUETE_R_ATTENTE;
 
    when REQUETE_R_ATTENTE =>
    request_en <= '0';
    if (request_valid = '0') then
        stateUR <= REQUETE_R_ATTENTE;
    elsif (request_valid = '1') then       
        donneeMemoire := request_value;
        stateUR <= REPONSE;
    end if;
    
    when REQUETE_P =>
    unpause <= '1';
    stateUR <= REQUETE_P_ATTENTE;
    
    when REQUETE_P_ATTENTE =>
    request_en <= '0';
    unpause <= '0';
    stateUR <= LECTURE;
    
    when REPONSE =>
    tx_dataFSM_valid <= '1';
    if ( donnee( 1 downto 0) = "11") then
       stateUR <= REPONSE_TYPE;
    elsif (donnee( 1 downto 0) = "10") then
       tx_dataFSM <= donnee;
    elsif (donnee( 1 downto 0) = "01") then
       stateUR <= REPONSE_TYPE;
    end if;
    
    when REPONSE_TYPE =>
        if (rx_busy = '1') then
            tx_dataFSM <= donnee;
            stateUR <= REPONSE_8;
        elsif (rx_busy = '0') then
            stateUR <= REPONSE_TYPE;
        end if;
        
    when REPONSE_8 =>
        if (rx_busy = '1') then
               tx_dataFSM <= donneeMemoire (7 downto 0);
               stateUR <= REPONSE_16;
        elsif (rx_busy = '0') then
               stateUR <= REPONSE_8;
        end if;
           
    when REPONSE_16 =>
        if (rx_busy = '1') then
               tx_dataFSM <= donneeMemoire (15 downto 8);
               stateUR <= REPONSE_24;
        elsif (rx_busy = '0') then
               stateUR <= REPONSE_16;
        end if;
           
    when REPONSE_24 =>
        if (rx_busy = '1') then
               tx_dataFSM <= donneeMemoire (23 downto 16);
               stateUR <= REPONSE_32;
        elsif (rx_busy = '0') then
               stateUR <= REPONSE_24;
        end if;
           
    when REPONSE_32 =>
        if (rx_busy = '1') then
               tx_dataFSM <= donneeMemoire (31 downto 24);
               tx_dataFSM_valid <= '0';
               stateUR <= LECTURE;
           elsif (rx_busy = '0') then
               stateUR <= REPONSE_32;
           end if;
    
    when OTHERS =>
        stateUR <= LECTURE;
        
        end case;
    end if;
end process;


end Behavioral;
