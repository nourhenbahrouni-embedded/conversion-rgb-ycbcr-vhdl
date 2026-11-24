--library ieee;
--use ieee.std_logic_1164.all;
--use ieee.numeric_std.all;
--
--entity conversion_gris is
--  port (
--    clk       : in  std_logic;
--    rst       : in  std_logic;
--    R         : in  std_logic_vector(7 downto 0);
--    G         : in  std_logic_vector(7 downto 0);
--    B         : in  std_logic_vector(7 downto 0);
--    valid_in  : in  std_logic;
--    Y         : out std_logic_vector(7 downto 0);
--    valid_out : out std_logic
--  );
--end entity conversion_gris;
--
--architecture rtl of conversion_gris is
--
--  constant COEF_R : unsigned(7 downto 0) := to_unsigned(77, 8);
--  constant COEF_G : unsigned(7 downto 0) := to_unsigned(150, 8);
--  constant COEF_B : unsigned(7 downto 0) := to_unsigned(29, 8);
--
--  signal p_r, p_g, p_b : unsigned(15 downto 0);
--  signal valid_1       : std_logic;
--  signal somme         : unsigned(15 downto 0);
--
--begin
--
--  -- ETAGE 1 : multiplications
--  etage1 : process (clk)
--  begin
--    if rising_edge(clk) then
--      if rst = '1' then
--        p_r     <= (others => '0');
--        p_g     <= (others => '0');
--        p_b     <= (others => '0');
--        valid_1 <= '0';
--      else
--        p_r     <= unsigned(R) * COEF_R;
--        p_g     <= unsigned(G) * COEF_G;
--        p_b     <= unsigned(B) * COEF_B;
--        valid_1 <= valid_in;
--      end if;
--    end if;
--  end process etage1;
--
--  -- ETAGE 2 : addition puis bits 15..8
--  somme <= p_r + p_g + p_b;
--
--  etage2 : process (clk)
--  begin
--    if rising_edge(clk) then
--      if rst = '1' then
--        Y         <= (others => '0');
--        valid_out <= '0';
--      else
--        Y         <= std_logic_vector(somme(15 downto 8));
--        valid_out <= valid_1;
--      end if;
--    end if;
--  end process etage2;
--
--end architecture rtl;









--------------------------------------------------------------------------------
-- tb_conversion.vhd  (ETAPES 4 et 5)
-- Testbench avec fichiers :
--   - lit image_rgb.txt (un pixel par ligne, 6 chiffres hexa : RRGGBB)
--   - envoie chaque pixel au module conversion_gris (un pixel par cycle)
--   - ecrit chaque Y valable dans gris_sortie.txt (2 chiffres hexa par ligne)
--
-- Les fichiers doivent etre dans le dossier de travail de ModelSim
-- (celui qui contient le dossier "work"), ou il faut donner le chemin complet.
--------------------------------------------------------------------------------
--library ieee;
--use ieee.std_logic_1164.all;
--use ieee.numeric_std.all;
--use std.textio.all;                 -- fichiers texte : file, line, readline, writeline
--use ieee.std_logic_textio.all;      -- hread / hwrite pour std_logic_vector
--
--entity tb_conversion is
--  generic (
--    FICHIER_ENTREE : string := "image_rgb.txt";
--    FICHIER_SORTIE : string := "gris_sortie.txt"
--  );
--end entity tb_conversion;
--
--architecture sim of tb_conversion is
--
--  constant PERIODE : time := 10 ns;
--
--  signal clk       : std_logic := '0';
--  signal rst       : std_logic := '1';
--  signal R, G, B   : std_logic_vector(7 downto 0) := (others => '0');
--  signal valid_in  : std_logic := '0';
--  signal Y         : std_logic_vector(7 downto 0);
--  signal valid_out : std_logic;
--
--  signal lecture_finie : boolean := false;
--  signal fin           : boolean := false;
--  signal nb_lus        : integer := 0;
--  signal nb_ecrits     : integer := 0;
--
--begin
--
--  ------------------------------------------------------------------------------
--  -- Le module teste
--  ------------------------------------------------------------------------------
--  dut : entity work.conversion_gris
--    port map (clk => clk, rst => rst, R => R, G => G, B => B,
--              valid_in => valid_in, Y => Y, valid_out => valid_out);
--
--  ------------------------------------------------------------------------------
--  -- Horloge (s'arrete quand fin = true) et reset
--  ------------------------------------------------------------------------------
--  horloge : process
--  begin
--    while not fin loop
--      clk <= '0'; wait for PERIODE / 2;
--      clk <= '1'; wait for PERIODE / 2;
--    end loop;
--    wait;
--  end process horloge;
--
--  rst <= '1', '0' after 2.5 * PERIODE;
--
--  ------------------------------------------------------------------------------
--  -- Process LECTURE : une ligne du fichier = un pixel = un cycle
--  ------------------------------------------------------------------------------
--  lecture : process
--    file     f_entree : text open read_mode is FICHIER_ENTREE;
--    variable ligne    : line;
--    variable pixel    : std_logic_vector(23 downto 0);
--    variable compte   : integer := 0;
--  begin
--    wait until rst = '0';
--
--    while not endfile(f_entree) loop
--      readline(f_entree, ligne);         -- 1. prendre une ligne du fichier
--      hread(ligne, pixel);               -- 2. texte "C86432" -> 24 bits
--
--      wait until rising_edge(clk);       -- 3. envoyer le pixel au circuit
--      R        <= pixel(23 downto 16);
--      G        <= pixel(15 downto 8);
--      B        <= pixel(7 downto 0);
--      valid_in <= '1';
--
--      compte := compte + 1;
--      nb_lus <= compte;
--    end loop;
--
--    wait until rising_edge(clk);         -- plus de pixel : valid_in a 0
--    valid_in      <= '0';
--    lecture_finie <= true;
--    wait;
--  end process lecture;
--
--  ------------------------------------------------------------------------------
--  -- Process ECRITURE : a chaque Y valable, on l'ecrit dans le fichier
--  ------------------------------------------------------------------------------
--  ecriture : process (clk)
--    file     f_sortie : text open write_mode is FICHIER_SORTIE;
--    variable ligne    : line;
--    variable compte   : integer := 0;
--  begin
--    if rising_edge(clk) and valid_out = '1' then
--      hwrite(ligne, Y);                  -- 1. ecrire Y en hexa sur la ligne
--      writeline(f_sortie, ligne);        -- 2. ajouter la ligne au fichier
--      compte    := compte + 1;
--      nb_ecrits <= compte;
--    end if;
--  end process ecriture;
--
--  ------------------------------------------------------------------------------
--  -- Fin de simulation : on attend que le pipeline se vide (2 cycles + marge)
--  ------------------------------------------------------------------------------
--  arret : process
--  begin
--    wait until lecture_finie;
--    for i in 1 to 5 loop
--      wait until rising_edge(clk);
--    end loop;
--
--    report "SIMULATION TERMINEE : " & integer'image(nb_lus) & " pixels lus, " &
--           integer'image(nb_ecrits) & " pixels ecrits dans " & FICHIER_SORTIE;
--    assert nb_lus = nb_ecrits
--      report "ERREUR : le nombre de pixels lus et ecrits est different !"
--      severity error;
--    fin <= true;
--    wait;
--  end process arret;
--
--end architecture sim;




--------------------------------------------------------------------------------
-- tb_matricage.vhd
-- Testbench avec fichiers (copie de tb_conversion, 5 changements marques CHANGE) :
--   - lit image_rgb.txt (un pixel par ligne, 6 chiffres hexa : RRGGBB)
--   - envoie chaque pixel au module matricage (un pixel par cycle)
--   - ecrit Y, Cb, Cr dans matricage_sortie.txt (6 chiffres hexa par ligne : YYCbCr)
--------------------------------------------------------------------------------





--- Matriçage + Conversion


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity matricage is
  port (
    clk       : in  std_logic;
    rst       : in  std_logic;
    R         : in  std_logic_vector(7 downto 0);
    G         : in  std_logic_vector(7 downto 0);
    B         : in  std_logic_vector(7 downto 0);
    valid_in  : in  std_logic;
    Y         : out std_logic_vector(7 downto 0);
    Cb        : out std_logic_vector(7 downto 0);   
    Cr        : out std_logic_vector(7 downto 0);   
    valid_out : out std_logic
  );
end entity matricage;

architecture rtl of matricage is

  -- Ligne Y (identique a conversion_gris)
  constant COEF_R : unsigned(7 downto 0) := to_unsigned(77, 8);
  constant COEF_G : unsigned(7 downto 0) := to_unsigned(150, 8);
  constant COEF_B : unsigned(7 downto 0) := to_unsigned(29, 8);

  -- Ligne Cb : -43 R - 85 G + 128 B (valeurs absolues)         
  constant COEF_CB_R : unsigned(7 downto 0) := to_unsigned(43, 8);
  constant COEF_CB_G : unsigned(7 downto 0) := to_unsigned(85, 8);
  constant COEF_CB_B : unsigned(7 downto 0) := to_unsigned(128, 8);

  -- Ligne Cr : 128 R - 107 G - 21 B (valeurs absolues)          
  constant COEF_CR_R : unsigned(7 downto 0) := to_unsigned(128, 8);
  constant COEF_CR_G : unsigned(7 downto 0) := to_unsigned(107, 8);
  constant COEF_CR_B : unsigned(7 downto 0) := to_unsigned(21, 8);

  -- +128 en sortie = +32768 avant la division par 256            
  constant OFFSET : unsigned(15 downto 0) := to_unsigned(32768, 16);

  -- Produits de la ligne Y (identique a conversion_gris)
  signal p_r, p_g, p_b    : unsigned(15 downto 0);
  -- Produits des lignes Cb et Cr                                 
  signal cb_r, cb_g, cb_b : unsigned(15 downto 0);
  signal cr_r, cr_g, cr_b : unsigned(15 downto 0);

  signal valid_1  : std_logic;
  signal somme    : unsigned(15 downto 0);                    
  signal somme_cb : unsigned(15 downto 0);                     
  signal somme_cr : unsigned(15 downto 0);                     

begin

  -- ETAGE 1 : multiplications (9 au lieu de 3)
  etage1 : process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        p_r     <= (others => '0');
        p_g     <= (others => '0');
        p_b     <= (others => '0');
        cb_r    <= (others => '0');                            
        cb_g    <= (others => '0');
        cb_b    <= (others => '0');
        cr_r    <= (others => '0');
        cr_g    <= (others => '0');
        cr_b    <= (others => '0');
        valid_1 <= '0';
      else
        p_r     <= unsigned(R) * COEF_R;
        p_g     <= unsigned(G) * COEF_G;
        p_b     <= unsigned(B) * COEF_B;
        cb_r    <= unsigned(R) * COEF_CB_R;                    
        cb_g    <= unsigned(G) * COEF_CB_G;
        cb_b    <= unsigned(B) * COEF_CB_B;
        cr_r    <= unsigned(R) * COEF_CR_R;
        cr_g    <= unsigned(G) * COEF_CR_G;
        cr_b    <= unsigned(B) * COEF_CR_B;
        valid_1 <= valid_in;
      end if;
    end if;
  end process etage1;

  -- ETAGE 2 : additions puis bits 15..8
  somme    <= p_r + p_g + p_b;                                
  somme_cb <= (cb_b + OFFSET) - (cb_r + cb_g);                 
  somme_cr <= (cr_r + OFFSET) - (cr_g + cr_b);                 

  etage2 : process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        Y         <= (others => '0');
        Cb        <= (others => '0');                          
        Cr        <= (others => '0');                          
        valid_out <= '0';
      else
        Y         <= std_logic_vector(somme(15 downto 8));
        Cb        <= std_logic_vector(somme_cb(15 downto 8));  
        Cr        <= std_logic_vector(somme_cr(15 downto 8));  
        valid_out <= valid_1;
      end if;
    end if;
  end process etage2;

end architecture rtl;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;                 -- fichiers texte : file, line, readline, writeline
use ieee.std_logic_textio.all;      -- hread / hwrite pour std_logic_vector

entity tb_matricage is                                         -- CHANGE 1
  generic (
    FICHIER_ENTREE : string := "image_rgb.txt";
    FICHIER_SORTIE : string := "matricage_sortie.txt"          -- CHANGE 2
  );
end entity tb_matricage;                                       -- CHANGE 1

architecture sim of tb_matricage is                            -- CHANGE 1

  constant PERIODE : time := 10 ns;

  signal clk       : std_logic := '0';
  signal rst       : std_logic := '1';
  signal R, G, B   : std_logic_vector(7 downto 0) := (others => '0');
  signal valid_in  : std_logic := '0';
  signal Y         : std_logic_vector(7 downto 0);
  signal Cb, Cr    : std_logic_vector(7 downto 0);             -- CHANGE 3
  signal valid_out : std_logic;

  signal lecture_finie : boolean := false;
  signal fin           : boolean := false;
  signal nb_lus        : integer := 0;
  signal nb_ecrits     : integer := 0;

begin

  ------------------------------------------------------------------------------
  -- Le module teste                                           -- CHANGE 4
  ------------------------------------------------------------------------------
  dut : entity work.matricage
    port map (clk => clk, rst => rst, R => R, G => G, B => B,
              valid_in => valid_in, Y => Y, Cb => Cb, Cr => Cr,
              valid_out => valid_out);

  ------------------------------------------------------------------------------
  -- Horloge (s'arrete quand fin = true) et reset
  ------------------------------------------------------------------------------
  horloge : process
  begin
    while not fin loop
      clk <= '0'; wait for PERIODE / 2;
      clk <= '1'; wait for PERIODE / 2;
    end loop;
    wait;
  end process horloge;

  rst <= '1', '0' after 2.5 * PERIODE;

  ------------------------------------------------------------------------------
  -- Process LECTURE : une ligne du fichier = un pixel = un cycle
  ------------------------------------------------------------------------------
  lecture : process
    file     f_entree : text open read_mode is FICHIER_ENTREE;
    variable ligne    : line;
    variable pixel    : std_logic_vector(23 downto 0);
    variable compte   : integer := 0;
  begin
    wait until rst = '0';

    while not endfile(f_entree) loop
      readline(f_entree, ligne);         -- 1. prendre une ligne du fichier
      hread(ligne, pixel);               -- 2. texte "CCB28C" -> 24 bits

      wait until rising_edge(clk);       -- 3. envoyer le pixel au circuit
      R        <= pixel(23 downto 16);
      G        <= pixel(15 downto 8);
      B        <= pixel(7 downto 0);
      valid_in <= '1';

      compte := compte + 1;
      nb_lus <= compte;
    end loop;

    wait until rising_edge(clk);         -- plus de pixel : valid_in a 0
    valid_in      <= '0';
    lecture_finie <= true;
    wait;
  end process lecture;

  ------------------------------------------------------------------------------
  -- Process ECRITURE : a chaque resultat valable, on ecrit Y Cb Cr   -- CHANGE 5
  ------------------------------------------------------------------------------
  ecriture : process (clk)
    file     f_sortie : text open write_mode is FICHIER_SORTIE;
    variable ligne    : line;
    variable resultat : std_logic_vector(23 downto 0);
    variable compte   : integer := 0;
  begin
    if rising_edge(clk) and valid_out = '1' then
      resultat := Y & Cb & Cr;           -- 1. coller Y, Cb, Cr (8+8+8 = 24 bits)
      hwrite(ligne, resultat);           -- 2. ecrire en hexa sur la ligne
      writeline(f_sortie, ligne);        -- 3. ajouter la ligne au fichier
      compte    := compte + 1;
      nb_ecrits <= compte;
    end if;
  end process ecriture;

  ------------------------------------------------------------------------------
  -- Fin de simulation : on attend que le pipeline se vide (2 cycles + marge)
  ------------------------------------------------------------------------------
  arret : process
  begin
    wait until lecture_finie;
    for i in 1 to 5 loop
      wait until rising_edge(clk);
    end loop;

    report "SIMULATION TERMINEE : " & integer'image(nb_lus) & " pixels lus, " &
           integer'image(nb_ecrits) & " pixels ecrits dans " & FICHIER_SORTIE;
    assert nb_lus = nb_ecrits
      report "ERREUR : le nombre de pixels lus et ecrits est different !"
      severity error;
    fin <= true;
    wait;
  end process arret;

end architecture sim;
--


