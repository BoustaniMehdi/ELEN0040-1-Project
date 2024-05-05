library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity SpaceShooter is
    port (
        clk_fast : in std_logic;
        clk_slow : in std_logic;
        move_left, move_right, shoot, control : in std_logic;
        rows : out bit_vector(1 to 7);
        cols_green : out bit_vector(1 to 5) := (others => '1');
        cols_red : out bit_vector(1 to 5) := (others => '1');
        dizaine: out std_logic_vector(3 downto 0) := (others => '0');
        unite: out std_logic_vector(3 downto 0) := (others => '0')
    );
end SpaceShooter;

architecture space_arch of SpaceShooter is

   -- Positions du joueur
	signal player_col : integer range 1 to 5 := 3;

	-- Logique du jeu
	signal play : boolean := false; -- Détecter si le joueur a lancé une partie ou non
	signal action : boolean := true; -- Ce booléen vaut false si un bouton a été pressé (moves & shoot)
	signal game_over : boolean := false; -- Détecter si le joueur a perdu la partie ou non
	signal menu : boolean := true; -- Détecter si le joueur est dans le menu ou non
	signal lives : integer range 0 to 3 := 3; -- Nombre de vies du joueur : 3 initialement

	-- Tirs du joueur
	signal bullet_row : integer range 0 to 7 := 7; -- Ligne courante de la balle tirée par le joueur
	signal bullet : boolean := false; -- Indication si notre joueur a tiré ou non
	signal touched : boolean := false; -- Indication si un obstacle a été touché ou non
	
	-- Obstacles
	signal obstacle_row : integer range 0 to 8 := 1; -- Position initiale de l'obstacle
	signal obstacle_col : integer range 1 to 5; -- Position horizontale de l'obstacle
	signal obstacle_speed : integer := 1; -- Vitesse de déplacement de l'obstacle
	signal delete_obstacle : boolean := false;
	signal rand_col : integer range 1 to 5 := 1; -- Colonne aléatoire pour l'obstable
	
	-- Faciliter l'affichage de la matrice selon la fréquence courante
	signal row_counter : natural range 1 to 7 := 1; -- Index de la ligne courante pour l'affichage du menu
	signal switch : natural range 1 to 3 := 1; -- Switch pour avoir une alternance entre les obstacles et le joueur

	-- 7 segments (0 to 99)
	subtype digit_type is integer range 0 to 9; -- Type pour les 7 segments
	signal score_dizaine : digit_type; -- Dizaine du 7 segments
	signal score_unite : digit_type; -- Unité du 7 segments
	
begin

   logic : process(clk_slow, clk_fast, move_left, move_right, shoot, control)
		
		variable obstacle_counter : integer range 0 to 20; -- Gérer la vitesse des obstacles 
		variable bullet_counter : integer range 0 to 5; -- Gérer la vitesse des tirs
		
   begin
      if rising_edge(clk_slow) then
            if(control = '1') then
                play <= true;
					 menu <= false;
            elsif (play) then
					if(move_right = '0' and move_left = '0' and shoot = '0') then
						action <= true;
					elsif(action) then
					  action <= false;
					  if move_left = '1' then
							-- Déplacer la LED vers la gauche
							if player_col > 1 then
								 player_col <= player_col - 1;
							end if;
					  elsif move_right = '1' then
							-- Déplacer la LED vers la droite
							if player_col < 5 then
								 player_col <= player_col + 1;
							end if;
						elsif shoot = '1' then
							-- Le joueur a tiré
							bullet <= true;
					  end if;
					end if;
					
					touched <= (bullet_row = obstacle_row and player_col = obstacle_col) and bullet; -- Si le tir a touché un obstacle, il vaut true. False sinon
					
					-- Si le tir a touché un obstacle ou est arrivé jusque la première ligne, on réinitialise le tir
					if touched or (bullet_row < 1) then
						bullet_row <= 7;
						bullet <= false;
					end if;
					
					bullet_counter := bullet_counter + 1; -- Utilisé pour diminuer la vitesse du tir
					if(bullet) then
						if bullet_counter = 2 then -- Après 2 rising edge de la clock, on peut déplacer la balle
							bullet_counter := 0;
							bullet_row <= bullet_row - 1;
						end if;
						
					end if;
					
					if touched then
						delete_obstacle <= true; -- On supprime l'obstacle s'il a été touché par un tir
						obstacle_row <= 1; -- On place l'obstacle à la premiere ligne (à corriger)
						obstacle_col <= rand_col; -- On place l'obstacle dans une colonne random
						touched <= false; -- Le nouvel obstacle n'a pas encore été touché
						
						-- On incrémente le score manuellement pour économiser les logic gates (optimisation)
						if(score_dizaine <= 9 and score_unite < 9) then
							if score_unite = 9 then
								score_dizaine <= score_dizaine + 1;
								score_unite <= 0;
							else
								score_unite <= score_unite + 1;
							end if;
						end if;
						
					end if;
					
					-- Si l'obstacle courant n'a pas été touché, on peut l'envoyer dans la direction du joueur
					if(not delete_obstacle) then
						obstacle_counter := obstacle_counter + 1;
						
						-- Facteur de ralentissement pour l'obstacle
						if obstacle_counter = 10 then
							obstacle_counter := 0;
							obstacle_row <= obstacle_row + obstacle_speed;
							
							-- Si l'obstacle n'a pas touché le joueur, on réinitialise sa position
							if obstacle_row > 7 then
								obstacle_row <= 1;
								obstacle_col <= rand_col;
							end if;
							
						end if;
					else
						delete_obstacle <= false; -- A corriger
					end if;
				end if;
        end if;
   end process logic;
   
	-- Random process pour la colonne des obstacles
	random : process(clk_fast)
	begin 
	  if rising_edge(clk_fast) then
			if rand_col = 5 then
				 rand_col <= 1;
			 else
				 rand_col <= rand_col + 1;
			 end if;
		end if;
	end process random;
	 
	display : process(clk_fast, control)	
	begin
		if rising_edge(clk_fast) then
			if play then
				
				-- Si l'obstacle touche le joueur, on diminue ses vies de 1
				if(obstacle_row = 7 and obstacle_col = player_col) then
					lives <= lives - 1;
				end if;
				
				-- La ligne continuellement allumée est celle du joueur (la dernière)
				rows <= "0000001";
				cols_green <= (others => '1');
				cols_red <= (others => '1');
				
				-- Premier rising edge, on affiche le joeur selon son état
				if switch = 1 then
					cols_green <= (others => '1');
					rows <= (others => '0');
					
					case lives is 
						when 3 => 
							cols_green(player_col) <= '0';
						when 2 => 
							cols_green(player_col) <= '0';
							cols_red(player_col) <= '0';
						when 1 => 
							cols_red(player_col) <= '0';
						when others =>
							game_over <= true;
					end case;
					
					rows(7) <= '1';
				
				-- Deuxième rising edge, on affiche l'obstacle
				elsif switch = 2 then
					if obstacle_row <= 7 then
						if not delete_obstacle then
							cols_red <= (others => '1');
							rows <= (others => '0');
							rows(obstacle_row) <= '1';
							cols_red(obstacle_col) <= '0';
						end if;
					end if;
				
				-- Troisième rising edge, on affiche le tir du joueur s'il a été envoyé
				elsif switch > 2 and (touched = false or bullet_row <= 1) and bullet then
					rows <= (others => '0');
					cols_red <= (others => '1');
					rows(bullet_row) <= '1';
					cols_red(player_col) <= '0';
				end if;
				
				switch <= switch + 1;
				
			-- Menu principal --
			elsif menu then
				case row_counter is 
					when 1 => 
						rows <= "0100010";
						cols_green <= "10111";
					when 2 =>
						rows <= "0010100";
						cols_green <= "10011";
					when 3 =>
						rows <= "0001000";
						cols_green <= "10001";
					when 4 =>
						rows <= "0001000";
						cols_green <= "10001";
					when 5 => 
						rows <= "0010100";
						cols_green <= "10011";
					when 6 => 
						rows <= "0100010";
						cols_green <= "10111";
					when others =>
						rows <= (others => '0');
						cols_red <= (others => '1');
				end case;
				row_counter <= row_counter + 1;
			end if;
			
			
			-- Mise à jour des 7 segments en fonction du score
			dizaine <= std_logic_vector(to_unsigned(score_dizaine, 4));
			unite <= std_logic_vector(to_unsigned(score_unite, 4));

		end if;
	end process display;
	

end architecture space_arch;






		
		