import "@skyra/discord-components-core";

import { LitElement, html } from "lit";

export class DiscordComponentsWrapper extends LitElement {
  public override render() {
    return html`
      <main id="demo">
        <h3 class="title">A normal conversation</h3>
        <discord-messages>
          <discord-message author="Alyx Vargas">
            Hey guys, I'm new here! Glad to be able to join you all!
          </discord-message>
          <discord-message
            author="Fenton Smart"
            avatar="https://raw.githubusercontent.com/skyra-project/discord-components-implementations/main/shared/public/avafive.png"
          >
            Hi, I'm new here too!
          </discord-message>
          <discord-message profile="maximillian">
            Hey, <discord-mention>Alyx Vargas</discord-mention> and
            <discord-mention>Dawn</discord-mention>. Welcome to our server!<br />Be
            sure to read through the
            <discord-mention type="channel">rules</discord-mention>. You can
            ping
            <discord-mention type="role" color="#70f0b4"
              >Support</discord-mention
            >
            if you need help.
          </discord-message>
          <discord-message profile="willard"
            >Hello everyone! How's it going?</discord-message
          >
          <discord-message author="Alyx Vargas" highlight>
            Thank you
            <discord-mention>Maximillian Osborn</discord-mention>!
          </discord-message>
          <discord-message
            author="Kayla Feeney"
            avatar="https://raw.githubusercontent.com/skyra-project/discord-components-implementations/main/shared/public/avafour.png"
          >
            I'm doing well, <discord-mention>Willard Walton</discord-mention>.
            What about yourself?
          </discord-message>
          <discord-message profile="willard">
            s!8ball How am I doing today?
          </discord-message>
          <discord-message profile="skyra"> Yes. </discord-message>
        </discord-messages>
      </main>
    `;
  }
}

customElements.define("discord-components-wrapper", DiscordComponentsWrapper);
