<div align="center">
    <img src="https://raw.githubusercontent.com/folktalesgaming/gulam-chor/a8ecd1813606b27f019c28d7374c721b9dd531d4/icon.svg" />
</div>

# Gulam Chor (Jack the theif)

Gulam Chor is a classic card game where one of the Jack`(Gulam)` is removed from the pack of cards and all the remaining cards are shuffled and divided among the players. After that the players will remove the pair cards and one by one players will pick the card in random from next player until all the cards are removed except for the odd Jack at which point the game ends and the player with the odd jack is the loser.

## Few screenshots of games

These screenshots contains the screenshot during the development of the game, so might not represent the final game (`i.e the MVP version of the game`)

**Main Menu** | **Exit Model**
--|--
![Main menu](https://github.com/folktalesgaming/gulam-chor/blob/main/git_assets/gulam_chor_main_menu.png?raw=true) | ![Exit Model](https://github.com/folktalesgaming/gulam-chor/blob/main/git_assets/gulam_chor_exit_popup.png?raw=true)

**Game Play Screen** | **Game Play Screen First Round** | **Game Play Picking** | **Game Play Picked Card**
--|--|--|--
![Game Play Screen](https://github.com/folktalesgaming/gulam-chor/blob/main/git_assets/gulam_chor_game_play.png?raw=true) | ![Game Play screen first round](https://github.com/folktalesgaming/gulam-chor/blob/main/git_assets/gulam_chor_game_play_first_round.png?raw=true) | ![Game Play Picking](https://github.com/folktalesgaming/gulam-chor/blob/main/git_assets/gulam_chor_picking.png?raw=true) | ![Game play picked](https://github.com/folktalesgaming/gulam-chor/blob/main/git_assets/gulam_chor_pick_by_player.png?raw=true)

**Game Settings Page** | **Game Paused Screen** | **Game Over Screen**
--|--|--
![Game setting page](https://github.com/folktalesgaming/gulam-chor/blob/main/git_assets/gulam_chor_settings.png?raw=true) | ![Game paused screen](https://github.com/folktalesgaming/gulam-chor/blob/main/git_assets/gulam_chor_paused.png?raw=true) | ![Game over screen](https://github.com/folktalesgaming/gulam-chor/blob/main/git_assets/gulam_chor_game_over.png?raw=true)

# Plans For the Game

## Game Modes

There will be two modes for the game `Classic Mode` and `Random Mode`.

### Classic Mode

- [x] Will be played out same as classic gulam chor.
- [x] One of the `JACK (GULAM)` will have one odd pair.

### Random Mode

- [x] Instead of the `JACK` being the odd one out, one random card will be odd one out

> Will be in the settings to toggle the random card instead of it being its own mode

## Card Skins

There is only one type of skin available for the card as seen below.

**Card Front** | **Card Back**
--|--
![skin card front](https://github.com/folktalesgaming/gulam-chor/blob/main/Assets/UI/Cards/card_a_spade.png?raw=true) | ![skin card back](https://github.com/folktalesgaming/gulam-chor/blob/main/Assets/UI/Cards/new_card_back.png?raw=true)

- [ ] Make more skins of cards available.

## Number of Players

For the MVP of the game the game will feature only `4 players mode` with 4 players needed by making the remaining player with `game AI` if there are less than 4 players to play.

- [ ] Make able to play more than 4 players.
- [x] ~~Make able to play `2 or 3 players mode` also.~~

> It turns out we need atleast 4 players to make this game fun to play (user feedbacks)

## Future Plans

Some of the future plans for the game.

> This project is a hobby project and a learning project for game development in [GODOT](https://godotengine.org/) hence these future plans might be discontinued later for certain reasons.

- [ ] Additional Game Mode `Extreme Mode` where the card pairs must be of same color `(i.e black-black and red-red`) **`[Being worked on as setting to turn on and off called extreme mode or color mode]`**
- [ ] Addition of powerup cards such as `reverse (to reverse the way of picking cards)`, `block (to block the next player from picking the card)`, etc
- [ ] Ability to create personal Lobby to invite and play with friends.
