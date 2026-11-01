# Assignment checklist

| Requirement | Implementation / evidence |
| --- | --- |
| Dark game window | `conf.lua` and background in `love.load()` |
| Two rectangular paddles | `game.player1`, `game.player2`, and `ui.lua` |
| Position, size, and speed in Lua tables | Paddle tables in `love.load()` |
| W / S for player 1 | `movePaddle(game.player1, "w", "s", step)` |
| Up / Down for player 2 | `movePaddle(game.player2, "up", "down", step)` |
| Delta-time movement | `love.update(dt)`, `movePaddle`, and `moveBall` |
| Paddle bounds | `clamp` against the court's top and bottom |
| Part 1 commit | First Git commit: `Part 1: window and paddles` |
| Ball starts centered | `resetBall()` |
| Horizontal and vertical velocity | `ball.dx` and `ball.dy`, explained in README and Arabic guide |
| Bounce off top and bottom | Vertical direction reversal in `moveBall()` |
| Rectangle collision function | `game.collides(a, b)` uses four AABB comparisons |
| Bounce off both paddles | `paddleHit()` reverses horizontal direction |
| Ball does not stick inside a paddle | Position correction in `paddleHit()` |
| Required own change | 4.5% horizontal speed increase per paddle hit, capped at 750 px/s |
| Own change described in README | `My own change` section |
| One-paragraph game description | `About the game` section in README |
| Run command | `love .` in README |
| Controls | Controls table in README |
| At least one screenshot | `screenshots/gameplay.png` and `screenshots/ready.png`, linked in README |
| Short demo video | `demo/pong-demo.mp4`, linked in README; GIF preview also embedded |
| Full name and class / section | Student must replace the two TODO fields in README |
| Public GitHub repository named pong-love2d | Ready locally; student must create the public repository and push it |

The PDF refers to Part 1 and Part 2 videos. This implementation follows the written requirements in the supplied PDF; access to those videos is not claimed.
