let player = {
    name: "Player",
    chips: 200
}

let deck = []
let cards = []
let sum = 0
let hasBlackJack = false
let isAlive = false
let message = ""


let messageEl = document.getElementById("message-el")
// let sumEl = document.getElementById("sum-el")
let sumEl = document.querySelector("#sum-el")
let cardsEl = document.getElementById("cards-el")
let playerEl = document.getElementById("player-el")

playerEl.textContent = player.name + ": $" + player.chips

const suits = ["H", "D", "C", "S"] // Hearts, Diamonds, Clubs, Spades
const values = [
    {name:"2", value:2}, {name:"3", value:3}, {name:"4", value:4}, {name:"5", value:5},
    {name:"6", value:6}, {name:"7", value:7}, {name:"8", value:8}, {name:"9", value:9},
    {name:"10", value:10}, {name:"J", value:10}, {name:"Q", value:10}, {name:"K", value:10}, {name:"A", value:11}
];


function buildDeck() {
    deck = []
    for (let s of suits) {
        for (let v of values) {
            let card = {
                name: v.name,
                value: v.value,
                suit: s,
                img: `images/${v.name}_${s}.png` // image path based on naming convention
            }
            deck.push(card)
        }
    }
    shuffleDeck()
}

function shuffleDeck() {
    for (let i = deck.length - 1; i > 0; i--) {
        let randomIndex = Math.floor(Math.random() * (i + 1))
        let temp = deck[i]
        deck[i] = deck[randomIndex]
        deck[randomIndex] = temp
    }
}

function drawCard() {
    return deck.pop()
}

function adjustForAce(hand) {
    let sum = hand.reduce((acc, card) => acc + card.value, 0)
    while (sum > 21 && hand.some(card => card.value === 11)) {
        let aceIndex = hand.findIndex(card => card.value === 11)
        hand[aceIndex].value = 1
        sum = hand.reduce((acc, card) => acc + card.value, 0)
    }
    return sum
}

// function getRandomCard() {
//     let randomCard = Math.ceil(Math.random() * 12)
//     if (randomCard === 1) {
//         return 11
//     } else if (randomCard > 10) {
//         return 10
//     }
//     console.log(randomCard)
//     return randomCard

// }


function startGame() {
    // let firstCard = getRandomCard()
    // let secondCard = getRandomCard()

    buildDeck()
    isAlive = true
    hasBlackJack = false
    // cards = [firstCard, secondCard]
    cards = [drawCard(), drawCard()]
    sum = adjustForAce([cards])
    renderGame()
    
}

function renderGame() {
    // cardsEl.textContent = "Cards: " + firstCard + " " + secondCard
    cardsEl.innerHTML = "<strong>Cards:</strong> "
    const suitEmojis = {H:'♥', D:'♦', C:'♣', S:'♠'}

    for (let i = 0; i < cards.length; i++) {
        // If the image fails to load, onerror replaces it with a styled div
        cardsEl.innerHTML += `<img 
            src="${cards[i].img}" 
            alt="${cards[i].name} of ${cards[i].suit}" 
            style="width:50px;height:auto;margin:5px;"
            onerror="this.onerror=null;this.outerHTML='<div class=\\'card-box\\' style=\\'display:inline-block;width:50px;height:70px;border:1px solid #000;padding:5px;text-align:center;vertical-align:middle;font-size:20px;line-height:60px;\\'>${cards[i].name}${suitEmojis[cards[i].suit]}</div>';">`;
    }

    // for(let i = 0; i < cards.length; i++) {
    //     cardsEl.textContent += cards[i] + " "
    // }

    sumEl.textContent = "Sum: " + sum
    if (sum < 21) {
        message = "Do you want to draw a new card?"
    } else if (sum === 21) {
        message = "Win"
        hasBlackJack = true
    } else {
        message = "Lost"
        isAlive = false
    }
    messageEl.textContent = message
}

function newCard(){
    console.log("Drawing a new card from the deck")

    let newCard = getRandomCard()

    sum += newCard
    cards.push(newCard)
    renderGame()
}

console.log(hasBlackJack)