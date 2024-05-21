# Kiwii

![Time spent on this project](https://wakapi.rapougnac.moe/api/badge/Rapougnac/interval:today/project:Kiwii?color=D0BCFF&label=Kiwii)

A Discord bot made with [nyxx](https://pub.dev/packages/nyxx) and [nyxx_commands](https://pub.dev/packages/nyxx_commands)!

### Getting started
#### Development
This brick includes a [devcontainer](https://code.visualstudio.com/docs/devcontainers/containers) to make developing with Docker and docker-compose easier. Devcontainers allow you to have access to your other docker-compose services such as databases without having to run them manually on your host machine.

If you're using a devcontainer-compatible IDE, you can follow the setup instructions for that IDE:
- vscode: https://code.visualstudio.com/docs/devcontainers/containers#_getting-started
- GitHub codespaces: https://docs.github.com/en/codespaces/developing-in-codespaces/creating-a-codespace-for-a-repository
- JetBrains: Local devcontainers are currently unsupported. Follow the instructions for GitHub codespaces, then [connect to it from your IDE](https://docs.github.com/en/codespaces/developing-in-codespaces/opening-an-existing-codespace?tool=jetbrains).

Once you're ready to open your container, rename `.env.example` to `.env` and replace the placeholders with their real values. Then, you can open your project in the devcontainer:
- vscode: Run the  `Dev Containers: Reopen in Container` command from the command palette
- GitHub codespaces: https://docs.github.com/en/codespaces/developing-in-codespaces/opening-an-existing-codespace

#### Running your bot
To run your bot, make sure that you have set up your `.env` file correctly, then run `docker compose up`. Add the `--build` flag if you have made changes to your bot since the last time it started, and add the `-d` flag if you want it to run in the background.

To stop your bot, either press `Ctrl+C` if you didn't use the `-d` flag or run `docker compose down`.

### Next steps

Now that you've created your project, here's what to do next:
- Check out the [example bot](https://github.com/nyxx-discord/running_on_dart)
- Join the [support server](https://discord.gg/nyxx)
- Visit the [docs](https://pub.dev/documentation/nyxx_commands/latest)

<!--
TODO: Describe your app here

You can describe how to run it, what it does or link to a support server.
-->
