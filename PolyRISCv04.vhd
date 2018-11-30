--
-- polyRISC.vhd
--
-- Pierre Langlois
-- v. 0.2 2014/11/11 avec Hamza Bendaoudi: réécriture des types des instructions en constantes pour accomoder la synthèse
-- v. 0.3 2015/3/12: rendre le code conforme au diagramme, corrections et simplifications
-- v. 0.4 2017/11/09 par Jeferson. Ajouté des instructions mul et mac. Le signal stopped était ajouté.
-- La vérification n'est pas complète!
--	- branchements
--	- opérations de l'UAL
-- sans pipeline
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity polyRISC is
	generic (
		Nreg : integer := 32; -- nombre de registres
		Wd : integer := 16; -- largeur du chemin des données en bits
		Mi : integer := 8; -- nombre de bits d'adresse de la mémoire d'instructions
		Md : integer := 8; -- nombre de bits d'adresse de la mémoire des données
		WImm : integer := 16; -- nombre de bits des valeurs immédiates
		Implement_Mul : boolean := true; -- Impemente la multiplication
		Implement_Mac : boolean := true -- Impemente le MAC
	);
	port(
	    
		 reset, CLK : in std_logic;
		 stopped : out std_logic;
		 request_typePoly_rx: in std_logic_vector( 15 downto 0);
		 request_en_Poly_rx : in std_logic;
		 unpause_Poly : in std_logic;
		 
		  request_typePoly_tx: out std_logic_vector( 15 downto 0);
          request_value_tx : out std_logic_vector( 31 downto 0);
          request_vld_tx : out std_logic
	);
end polyRISC;

architecture arch of polyRISC is


type requeteType is (FLAG_TYPE, MEMOIRE_TYPE, REGISTRE_TYPE);
signal requeteState : requeteType;




-------------------------------------------------------------------------------
-- signaux du bloc des registres
--
type lesRegistres_type is array(0 to Nreg - 1) of signed(Wd - 1 downto 0);
signal lesRegistres : lesRegistres_type;
signal regHaute, regBasse : signed(Wd - 1 downto 0);

signal A, B : signed(Wd - 1 downto 0);
signal donneeBR : signed(2*Wd - 1 downto 0);
signal choixA, choixB, choixCharge : integer range 0 to Nreg - 1;
signal chargeBR : std_logic;
signal chargeHB : std_logic;
signal choixDonnee_BR : natural range 0 to 1;

-------------------------------------------------------------------------------
-- signaux de l'UAL	
--
signal op_UAL : natural range 0 to 11;
signal valeur : signed(Wd - 1 downto 0);
signal choixB_UAL : natural range 0 to 1;
signal F : signed(2*Wd - 1 downto 0);
signal Z, N : std_logic;

-- encodage des opérations
constant passeA : natural := 0;
constant passeB : natural := 1;
constant AplusB : natural := 2; 
constant AmoinsB : natural := 3;
constant AetB : natural := 4; 
constant AouB : natural := 5;
constant nonA : natural := 6; 
constant AouxB : natural := 7;
constant AfoisB : natural := 8;
constant passeRegB : natural := 9;
constant passeRegH : natural := 10;
constant mac : natural := 11;

-------------------------------------------------------------------------------
-- signaux de l'unité de branchement
--
signal brancher : std_logic;
signal condition : natural range 0 to 7;

-- encodage des conditions de branchement
constant egal : natural := 0; constant diff : natural := 1;
constant ppq : natural := 2; constant pgq : natural := 3;
constant ppe : natural := 4; constant pge : natural := 5;
constant toujours : natural := 6; constant jamais : natural := 7;

-------------------------------------------------------------------------------
-- signaux de la mémoire des données
--
signal charge_MD : std_logic;

type memoireDonnees_type is array(0 to 2 ** Md - 1) of signed(Wd - 1 downto 0);
signal memoireDonnees : memoireDonnees_type := (
0 => to_signed(0, Wd),
1 => to_signed(1, Wd),
2 => to_signed(2, Wd),
3 => to_signed(3, Wd),
4 => to_signed(10, Wd),
5 => to_signed(20, Wd),
6 => to_signed(30, Wd),
7 => to_signed(40, Wd),
others => to_signed(0, Wd)
); 

-------------------------------------------------------------------------------
-- signaux de la mémoire des instructions
--

-- le compteur de programme
signal CP : integer range 0 to (2 ** Mi - 1);

-- catégories d'instructions
constant reg : natural := 0;
constant reg_valeur : natural := 1;
constant branchement : natural := 2;
constant memoire : natural := 3;

-- détails d'instructions pour la catégorie mémoire
constant lireMemoire : natural := 0;
constant ecrireMemoire : natural := 1;

-- structure pour l'encodage d'une instruction
type instruction_type is record
	categorie	: natural range 0 to 3;
	details		: natural range 0 to 15;
	reg1		: natural range 0 to Nreg - 1;
	reg2		: natural range 0 to Nreg - 1;
	valeur		: integer range -2 ** (WImm - 1) to 2 ** (WImm - 1) - 1;
end record;
signal instruction : instruction_type;

-- instructions prédéfinies
constant NOP : instruction_type := (branchement, jamais, 0, 0, 0);
constant STOP : instruction_type := (branchement, toujours, 0, 0, 0);

-- mémoire des instructions et définition du programme
type memoireInstructions_type is array (0 to 2 ** Mi - 1) of instruction_type;

function init_mem return memoireInstructions_type is
begin
	if Implement_Mac then
		-- Kernel Array multiplication
		return
		((reg_valeur, passeB, 0, 0, 0), 	--  R0 := 0;
		(reg_valeur, afoisb, 0, 0, 0), 		--  R3 := 7;
		(reg_valeur, passeB, 3, 0, 7), 		--  R3 := 7;
		(branchement, pgq, 3, 0, 6), 		--  si R0 > R3 goto 6;
		(reg_valeur, AplusB, 0, 0, 1), 		--  R0 := R0 + 1;
		(memoire, lirememoire, 1, 0, 0),	--  R1 := M[R0(0)];
		(memoire, lirememoire, 2, 0, 4),	--  R2 := M[R0(4)];
		(reg, mac, 1, 1 , 2),				--  RHB := MAC(R1, R2);
		(branchement, toujours, 0, 0, -5),	--  goto 3
		(reg, passeRegB, 3, 0 , 0), 		--  R3 := RB;
		(memoire, ecrirememoire, 3, 0, 0),	--  M[R0(8)] := R3;
		(reg, passeRegH, 3, 0 , 0), 		--  R3 := RH;
		(memoire, ecrirememoire, 3, 0, 1),	--  M[R0(9)] := R3;
		STOP,
		others => NOP);
	elsif Implement_Mul then
		-- Kernel Array multiplication
		return
		((reg_valeur, passeB, 0, 0, 0), 	--  R0 := 0;
		(reg_valeur, passeB, 5, 0, 0), 		--  R5 := 0;
		(reg_valeur, afoisb, 0, 0, 0), 		--  R3 := 7;
		(reg_valeur, passeB, 3, 0, 7), 		--  R3 := 7;
		(branchement, pgq, 3, 0, 8), 		--  si R0 > R3 goto 6;
		(reg_valeur, AplusB, 0, 0, 1), 		--  R0 := R0 + 1;
		(memoire, lirememoire, 1, 0, 0),	--  R1 := M[R0(0)];
		(memoire, lirememoire, 2, 0, 4),	--  R2 := M[R0(4)];
		(reg, afoisb, 1, 1, 2),				--  RHB := R1*R2;
		(reg, passeRegB, 4, 0, 0), 			--  R4 := RB;
		(reg, aplusb, 5, 5, 4), 			--  R5 := R5 + R4;
		(branchement, toujours, 0, 0, -7),	--  goto 2
		(memoire, ecrirememoire, 5, 0, 0),	--  M[R0(8)] := R3;
		STOP,
		others => NOP);
	else
		return
		(
		-- quelques opérations sur des registres
		(reg_valeur, passeB, 2, 0 , 0), --  R2 := 0;
		(reg_valeur, passeB, 0, 0, 12), --  R0 := 12;
		(reg_valeur, passeB, 1, 0 , 7), --  R1 := 7;
		(reg, AplusB, 0, 0 , 1), 		--  R0 := R0 + R1;
		(reg, AouxB, 1, 0 , 1), 		--  R1 := R0 OUX R1;
		(reg_valeur, AplusB, 1, 1, -3), --  R1 := R1 - 3;
		(branchement, pgq, 2, 1, -1), 	--  si R1 > 0 goto -1;
		-- valeur absolue: M[3] = abs(M[0], M[1])
		(reg_valeur, passeB, 0, 0, 0), 		--  R0 := 0;
		(memoire, lirememoire, 1, 0, 0),	--  R1 := M[0];
		(memoire, lirememoire, 2, 0, 1),	--  R2 := M[1];
		(branchement, pgq, 2, 1, 3), 	-- si R1 > R2, goto 5
		(reg, AmoinsB, 3, 2, 1),		-- R3 := R2 - R1
		(branchement, toujours, 0, 0, 2),	-- goto 6
		(reg, AmoinsB, 3, 1, 2),		-- R3 := R1 - R2
		(memoire, ecrirememoire, 3, 0, 3),	-- M[3] := R3
		STOP,
		others => NOP);
	end if;	

end function;

constant memoireInstructions : memoireInstructions_type := init_mem; 

-------------------------------------------------------------------------------
-- le corps de l'architecture
begin
	
	stopped <= '1' when instruction = STOP else '0';
	
	-------------------------------------------------------------------------------
	-- multiplexeur pour choisir l'entrée du bloc des registres
	process(choixDonnee_BR, F, memoireDonnees)
	begin
		case choixDonnee_BR is
			when 0 =>
			donneeBR <= F;
			when 1 =>
			-- mod 2^Md pour ne garder que les Md bits les moins significatifs
			-- Nécessaire pour la simulation dans le cas où un glitch se produit sur F
			-- et que la valeur est temporairement négative.
			donneeBR <= resize(memoireDonnees(to_integer(F(Wd - 1 downto 0)) mod 2 ** Md), donneeBR'length);
		end case;
	end process;

	-------------------------------------------------------------------------------
	-- bloc des registres
	process (CLK, reset)
	begin
		if rising_edge(CLK) then
			if reset = '1' then
				lesRegistres <= (others => (others => '0'));
				regHaute	<= (others => '0');
				regBasse	<= (others => '0');
			else
				if chargeBR = '1' then
					lesRegistres(choixCharge) <= resize(donneeBR, Wd);
				end if;
				if chargeHB = '1' and (Implement_Mul or Implement_Mac) then
					regBasse	<= donneeBR(Wd - 1 downto 0);
					regHaute	<= donneeBR(donneeBR'high downto Wd);
				end if;
			end if;
		end if;
	end process;

	A <= regBasse when instruction.details = passeRegB and (Implement_Mul or Implement_Mac) else lesRegistres(choixA);
	B <= regHaute when instruction.details = passeRegH and (Implement_Mul or Implement_Mac) else lesRegistres(choixB);
	
	-------------------------------------------------------------------------------
	-- UAL
	process(A, B, valeur, choixB_UAL, op_UAL, regBasse, regHaute)
	variable B_UAL : signed(Wd - 1 downto 0);
	variable F_UAL : signed(2*Wd - 1 downto 0);
	begin
		
		-- multiplexeur pour l'entrée B
		if choixB_UAL = 0 then
			B_UAL := B;
		else
			B_UAL := valeur;
		end if;
		
		-- modélisation des opérations de l'UAL
		case op_UAL is	
			when passeA | passeRegB => 
				F_UAL := resize(A, F_UAL'length);
			when passeB | passeRegH => 
				F_UAL := resize(B_UAL, F_UAL'length);
			when AplusB => 
				F_UAL := resize(A + B_UAL, F_UAL'length);
			when AmoinsB => 
				F_UAL := resize(A - B_UAL, F_UAL'length);
			when AetB => 
				F_UAL := resize(A and B_UAL, F_UAL'length);
			when AouB =>
				F_UAL := resize(A or B_UAL, F_UAL'length);
			when nonA => 
				F_UAL := resize(not(A), F_UAL'length);
			when AouxB =>
				F_UAL := resize(A xor B_UAL, F_UAL'length);
			when AfoisB => 
				if (Implement_Mul or Implement_Mac) then
					F_UAL := A*B_UAL;
				else
					null;
				end if;
			when mac => 
				if Implement_Mac then
					F_UAL := resize(A*B_UAL + resize(regHaute & regBasse, F_UAL'length), F_UAL'length);
				else
					null;
				end if;
			when others =>
				null;
		end case;
		
		-- drapeaux pour l'unité de branchement
		if F_UAL = 0 then
			Z <= '1';
		else
			Z <= '0';
		end if;
		N <= F_UAL(F_UAL'left);
		
		-- sortie de l'UAL
		F <= F_UAL;
			
	end process; 
	
	-------------------------------------------------------------------------------
	-- unité de branchement
	process(Z, N, condition)
	begin			   
		case condition is
			when egal => brancher <= Z;
			when diff => brancher <= not(Z);
			when ppq => brancher <= N;
			when pgq => brancher <= not(N) and not(Z);
			when ppe => brancher <= N or Z;				
			when pge => brancher <= not(N) or Z;
			when toujours => brancher <= '1';
			when jamais => brancher <= '0';
		end case;
	end process;
	
	-------------------------------------------------------------------------------
	-- mémoire des données
	process (CLK)
	begin
		if rising_edge(CLK) then 
			if charge_MD = '1' then
				-- mod 2^Md pour ne garder que les Md bits les moins significatifs
				-- Nécessaire pour la simulation dans le cas où un glitch se produit sur F
				-- et que la valeur est temporairement négative.
				memoireDonnees(to_integer(F) mod 2 ** Md) <= B;
			end if;
		end if;
	end process; 
	
	-------------------------------------------------------------------------------
	-- compteur de programme
	process (CLK, reset)
	begin
		if rising_edge(CLK) then
			if reset = '1' then
				CP <= 0;
			else
				if (brancher = '1') then 
				    if (unpause_Poly = '1') then
			
				            CP <= CP + 1;
				       
				    else 
				        CP <= CP + instruction.valeur;
				        end if; 
				else
					CP <= CP + 1;
				end if;
			end if;
		end if;
	end process;  
	
	-------------------------------------------------------------------------------
	-- mémoire des instructions
	-- La mémoire des instructions est une ROM, elle est constante.
	-- Elle est déclarée et définie dans la partie déclarative de l'architecture.
	instruction <= memoireInstructions(CP);

	-------------------------------------------------------------------------------
	-- décodage des instructions pour les signaux de contrôle du chemin des données
	process (instruction)
	begin		

		-------------------------------------------------------------------------------
		-- pour le bloc des registres

		-- chargeBR
		if ((instruction.categorie = reg or
			instruction.categorie = reg_valeur) and 
			(instruction.details /= afoisb and instruction.details /= mac)) or
			(instruction.categorie = memoire and instruction.details = lirememoire) then
			chargeBR <= '1';
		else
			chargeBR <= '0';
		end if;	

		-- chargeHB
		if (instruction.categorie = reg or
			instruction.categorie = reg_valeur) and 
			(instruction.details = afoisb or instruction.details = mac) and 
			(Implement_Mul or Implement_Mac) then
			chargeHB <= '1';
		else
			chargeHB <= '0';
		end if;	

		-- choixCharge
		choixCharge <= instruction.reg1;

		-- choixA et choixB
		if (instruction.categorie = reg) then
			choixA <= instruction.reg2;
			choixB <= instruction.valeur mod Nreg; -- on garde seulement les log2(Nreg) bits les moins significatifs
		elsif (instruction.categorie = reg_valeur) then
			choixA <= instruction.reg2;
			choixB <= instruction.reg1;
		elsif (instruction.categorie = branchement) then
			choixA <= instruction.reg2;
			choixB <= instruction.reg1;
		elsif (instruction.categorie = memoire) then
			if (instruction.details = lirememoire) then
				choixA <= instruction.reg2;
				choixB <= instruction.reg1; -- valeur bidon, le port B n'est pas lu
--			elsif (instruction.categorie = ecrirememoire) then
			else
				choixA <= instruction.reg2;
				choixB <= instruction.reg1;
			end if;
		else -- en principe on n'arrive jamais ici
			choixA <= 0; -- valeur bidon
			choixB <= 0; -- valeur bidon
		end if;	

		-------------------------------------------------------------------------------
		-- pour l'UAL

		-- valeur
		valeur <= to_signed(instruction.valeur, Wd);

		-- choixB_UAL
		if (instruction.categorie = reg or instruction.categorie = branchement) then
			choixB_UAL <= 0;
		else
			choixB_UAL <= 1;
		end if;
		
		-- op_UAL
		if (instruction.categorie = reg or instruction.categorie = reg_valeur) then
			op_UAL <= instruction.details;
		elsif (instruction.categorie = branchement) then
			-- pour faire la comparaison entre les opérandes
			op_UAL <= AmoinsB;
		else
			-- lire et écrire la mémoire, calcul de l'adresse effective
			op_UAL <= AplusB;
		end if;

		-------------------------------------------------------------------------------
		-- pour l'unité de branchement
		if (instruction.categorie = branchement) then
			condition <= instruction.details;
		else
			condition <= jamais;
		end if;
		
		-------------------------------------------------------------------------------
		-- pour la mémoire des données
		if (instruction.categorie = memoire and instruction.details = ecrireMemoire) then
			charge_MD <= '1';
		else
			charge_MD <= '0';
		end if;
		
		-------------------------------------------------------------------------------
		-- pour le multiplexeur de l'entrée du bloc des registres
		if instruction.categorie = memoire then
			choixDonnee_BR <= 1;
		else
			choixDonnee_BR <= 0;
		end if;
		
	end process; 
	
	
 	

process (clk) is
variable typeETflag : std_logic_vector (15 downto 0);
begin
typeETflag := request_typePoly_rx;
        if ( request_typePoly_rx ( 1 downto 0) = "11") then
            requeteState <= MEMOIRE_TYPE;
        elsif (request_typePoly_rx( 1 downto 0) = "10") then
            requeteState <= FLAG_TYPE;
        elsif (request_typePoly_rx( 1 downto 0) = "01") then
            requeteState <= REGISTRE_TYPE;
            end if;
            
case requeteState is

when FLAG_TYPE =>
 if ( request_en_Poly_rx = '1') then
       typeETflag(2) := Z;
       typeETflag(3) := N;
       request_typePoly_tx <= typeETflag;
   end if;

when REGISTRE_TYPE =>
    if ( request_en_Poly_rx = '1') then
        request_typePoly_tx <= typeETflag;
        request_value_tx <= std_logic_vector(lesRegistres( to_integer(signed(request_typePoly_rx))));
    end if;
    
when MEMOIRE_TYPE =>
 if ( request_en_Poly_rx = '1') then
        request_typePoly_tx <= typeETflag;
       request_value_tx <= std_logic_vector(memoireDonnees( to_integer(signed(request_typePoly_rx))));
  
   end if;

end case;

end process;
	
	
	
end arch;
