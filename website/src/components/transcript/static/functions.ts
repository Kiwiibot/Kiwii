export const scrollToMessage =
  'document.addEventListener("click",t=>{let e=t.target;if(!e)return;let o=e?.getAttribute("data-goto");if(o){let r=document.getElementById(`m-${o}`);r?(r.scrollIntoView({behavior:"smooth",block:"center"}),r.style.backgroundColor="rgba(148, 156, 247, 0.1)",r.style.transition="background-color 0.5s ease",setTimeout(()=>{r.style.backgroundColor="transparent"},1e3)):console.warn("Message ${goto} not found.")}});';

export const revealSpoiler =
  'const s=document.querySelectorAll(".discord-spoiler");s.forEach(s=>s.addEventListener("click",()=>{if(s.classList.contains("discord-spoiler")){s.classList.remove("discord-spoiler");s.classList.add("discord-spoiler--revealed");}}));';
