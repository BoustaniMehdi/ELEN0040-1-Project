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

	-- Position actuelle des obstacles (modifications eventuelles)
	signal current_row : integer range 1 to 7 := 7;
	signal action : boolean := true;

	-- Logique du jeu
	signal play : boolean := false; -- Utilisé pour détecter si le joueur a lancé une partie ou non
	signal game_over : boolean := false; -- Utilisé pour détecter si le joueur a perdu la partie ou non
	signal menu : boolean := true;
	signal lives : integer range 0 to 3 := 3; -- Nombre de vies du joueur : 3 initialement

	signal bullet_row : integer range 0 to 7 := 7;

	signal obstacle_row : integer range 0 to 8 := 1; -- Position initiale de l'obstacle
	signal obstacle_col : integer range 1 to 5; -- Position horizontale de l'obstacle
	signal obstacle_speed : integer := 1; -- Vitesse de déplacement de l'obstacle
	signal delete_obstacle : boolean := false;

	signal rand_col : integer range 1 to 5 := 1; -- Utilisé pour généner une colonne aléatoire pour l'obstable
	signal row_counter : natural range 1 to 7 := 1; -- Utilisé pour afficher l'image du menu
	signal switch : natural range 1 to 3 := 1; -- Switch pour avoir une alternance entre les obstacles et le joueur

	signal bullet : boolean := false;
	signal touched : boolean := false;

	subtype digit_type is integer range 0 to 9;

	signal score_dizaine : digit_type;
	signal score_unite : digit_type;

begin

	logic : process(clk_slow, clk_fast, move_left, move_right, shoot, control)
			variable obstacle_counter : integer range 0 to 20;
			variable bullet_counter : integer range 0 to 5;
			
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
						bullet <= true;
					end if;
				end if;
				
				
				touched <= (bullet_row = obstacle_row and player_col = obstacle_col) and bullet;
				
				if touched or (bullet_row < 1) then
					bullet_row <= 7;
					bullet <= false;

				end if;
				bullet_counter := bullet_counter + 1;
				if(bullet) then
					if bullet_counter = 2 then
						bullet_counter := 0;
						bullet_row <= bullet_row - 1;
					end if;
					
				end if;
				
				if touched then
					delete_obstacle <= true;
					obstacle_row <= 1;
					obstacle_col <= rand_col;
					touched <= false;
					if(score_dizaine <= 9 and score_unite < 9) then
						if score_unite = 9 then
							score_dizaine <= score_dizaine + 1;
							score_unite <= 0;
						else
							score_unite <= score_unite + 1;
						end if;
					end if;
				end if;
				
				if(not delete_obstacle) then
					obstacle_counter := obstacle_counter + 1;
					if obstacle_counter = 10 then -- Facteur de ralentissement pour l'obstacle
						obstacle_counter := 0;
						obstacle_row <= obstacle_row + obstacle_speed;
						
						if obstacle_row > 7 then
							obstacle_row <= 1;
							obstacle_col <= rand_col;
						end if;
					end if;
				else
					delete_obstacle <= false;
				end if;
			end if;
		end if;
	end process logic;
    
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
					
				if(obstacle_row = 7 and obstacle_col = player_col) then
					lives <= lives - 1;
				end if;
				
				rows <= "0000001";
				cols_green <= (others => '1');
				cols_red <= (others => '1');
				
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

				elsif switch = 2 then
					if obstacle_row <= 7 then
						if not delete_obstacle then
							cols_red <= (others => '1');
							rows <= (others => '0');
							rows(obstacle_row) <= '1';
							cols_red(obstacle_col) <= '0';
						end if;
					end if;
				elsif switch > 2 and (touched = false or bullet_row <= 1) and bullet then
					rows <= (others => '0');
					cols_red <= (others => '1');
					rows(bullet_row) <= '1';
					cols_red(player_col) <= '0';
				end if;
				
				switch <= switch + 1;
			elsif menu then
				-- Menu principal --
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







		
		