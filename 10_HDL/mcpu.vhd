--
-- Minimal 8 Bit CPU
--
-- rev 15102001
--
-- 01-02/2001 Tim B"oscke
-- 10   /2001 slight changes for proper simulation.
--
-- t.boescke@tuhh.de
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-- use ieee.std_logic_unsigned.all;

entity CPU8BIT2 is
	port (	
		data:	inout	std_logic_vector(7 downto 0);
		adress:	out	std_logic_vector(5 downto 0);
		oe:		out	std_logic;
		we:		out	std_logic;		-- Asynchronous memory interface
		rst:	in	std_logic;
		clk:	in	std_logic);
end;

architecture CPU_ARCH of CPU8BIT2 is
	-- signal	akku:	std_logic_vector(8 downto 0);	-- akku(8) is carry !
	-- signal	adreg:	std_logic_vector(5 downto 0);
	-- signal 	pc:	std_logic_vector(5 downto 0);
	-- signal	states:	std_logic_vector(2 downto 0);
	signal	akku:	unsigned(8 downto 0);	-- akku(8) is carry !
	signal	adreg:	unsigned(5 downto 0);
	signal 	pc:		unsigned(5 downto 0);
	signal	states:	unsigned(2 downto 0);
begin
	process(clk,rst)
	begin

	if rising_edge(clk) then

		if (rst = '0') then 
			adreg	<= (others => '0');	-- start execution at memory location 0 
			states	<= "000";
			akku <= (others => '0');
			pc   <= (others => '0');
		else
			-- PC / Adress path
			if (states = "000") then 
				pc	<= adreg + 1; 
				adreg	<= unsigned(data(5 downto 0));
			else	
				adreg	<= pc;
			end if;

			-- ALU / Data Path
			case states is
				when "010" => akku <= ("0" & akku(7 downto 0)) + ("0" & unsigned(data)); 	-- add
				when "011" => akku(7 downto 0) <= akku(7 downto 0) nor unsigned(data);	-- nor
				when "101" => akku(8) <= '0';					-- branch not taken, clear carry
				when others => null;						-- instr. fetch, jcc taken (000), sta (001) 
			end case;						

			-- State machine
			if (states /= "000") then states <= "000"; 				-- fetch next opcode
			elsif (data(7 downto 6) = "11" and akku(8)='1') then states <= "101";	-- branch not taken
				else  states <= "0" & not unsigned(data(7 downto 6)); 			-- execute instruction	
			end if;	
		end if;
	end if;
	end process;
	
	-- output
	adress	<= std_logic_vector(adreg);
	data 	<= "ZZZZZZZZ" when states /= "001" else std_logic_vector(akku(7 downto 0));
	oe <= '1' when (clk='1' or states  = "001" or rst='0' or states = "101") else '0'; 	-- no memory access during reset and 
	we <= '1' when (clk='1' or states /= "001" or rst='0') else '0'; 			-- state "101" (branch not taken)
	
end CPU_ARCH;
	
