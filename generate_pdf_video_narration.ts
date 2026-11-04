import fs from 'node:fs'
import path from 'node:path'
function loadEnv(file:string){if(!fs.existsSync(file))return;for(const line of fs.readFileSync(file,'utf8').split(/\r?\n/)){const m=line.match(/^\s*([A-Z][A-Z0-9_]*)\s*=\s*(.*)\s*$/);if(!m||m[2].startsWith('«redacted:'))continue;let v=m[2];if((v.startsWith('"')&&v.endsWith('"'))||(v.startsWith("'")&&v.endsWith("'")))v=v.slice(1,-1);if(!process.env[m[1]])process.env[m[1]]=v}}
loadEnv('/Users/amaster/projectm/video-saas/.env.local'); loadEnv('/Users/amaster/projectm/video-saas/.env.local.bak')
const out='/Users/amaster/projectm/dronewiki-pdf-video/audio'; fs.rmSync(out,{recursive:true,force:true});fs.mkdirSync(out,{recursive:true})
const scenes=[
'DroneWiki는 드론 특화 AI 지식 플랫폼입니다. 부품과 설계 지식을 하나의 시스템으로 연결합니다.',
'드론 정보는 복잡하고 흩어져 있습니다. 여러 분야의 자료를 함께 이해해야 정확한 설계가 가능합니다.',
'DroneWiki는 자료를 수집하고, 온톨로지로 구조화한 뒤, 사람의 검증을 거쳐 지식으로 만듭니다.',
'2nd Brain 파이프라인은 원시 자료를 수집하고 관계를 연결해 재사용 가능한 지식으로 바꿉니다.',
'핵심은 온톨로지 엔진입니다. 부품과 조건의 관계를 구조화해 그럴듯한 오류를 줄입니다.',
'일반 AI가 추측에 머물 수 있다면, DroneWiki는 검증된 지식과 수치 기반 판단을 제공합니다.',
'사용자는 AI에게 질문하고, 운영자는 근거를 확인하며 지식을 직접 수정하고 확장할 수 있습니다.',
'아이디어는 하드웨어와 소프트웨어 조건을 거쳐 실제 드론 설계와 검증 단계로 발전합니다.',
'Git과 Markdown 기반의 2nd Brain, AI 모델, 웹 프론트엔드가 하나의 플랫폼으로 연결됩니다.',
'DroneWiki는 단순한 챗봇이 아닙니다. 검증된 지식으로 드론 설계를 돕는 신뢰할 수 있는 파트너입니다.'
]
async function main(){const {generateElevenLabsNarration}=await import('/Users/amaster/projectm/video-saas/lib/pipeline/elevenlabs-tts.ts');for(let i=0;i<scenes.length;i++){const r=await generateElevenLabsNarration(scenes[i],out,{filename:`page-${String(i+1).padStart(2,'0')}.mp3`,language:'ko',speed:1.1});fs.writeFileSync(path.join(out,`page-${String(i+1).padStart(2,'0')}.json`),JSON.stringify({page:i+1,text:scenes[i],durationSeconds:r.durationSeconds,audioPath:r.audioPath},null,2));console.log(JSON.stringify({page:i+1,durationSeconds:r.durationSeconds}))}}
main().catch(e=>{console.error(e);process.exit(1)})