import { Modal } from './Modal.js'

export class Calendar {
  constructor() {
    this.state = {
      viewDate: new Date(),
      events: JSON.parse(localStorage.getItem('calendarEvents') || '{}'),
      selectedDate: null
    }

    this.monthNames = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ]
    this.weekdays = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat']

    this.monthDisplay = document.getElementById('monthDisplay')
    this.daysEl = document.getElementById('days')
    this.weekdaysEl = document.getElementById('weekdays')

    this.modal = new Modal(this)
    this.bindControls()
    this.render()
  }

  bindControls() {
    document.getElementById('prev').addEventListener('click', () => this.changeMonth(-1))
    document.getElementById('next').addEventListener('click', () => this.changeMonth(1))
    document.getElementById('todayBtn').addEventListener('click', () => {
      this.state.viewDate = new Date()
      this.render()
    })

    this.daysEl.addEventListener('keydown', (e) => {
      if (e.key === 'ArrowLeft') this.changeMonth(-1)
      if (e.key === 'ArrowRight') this.changeMonth(1)
      if (e.key === 'Home') { this.state.viewDate = new Date(); this.render() }
    })
  }

  saveEvents() {
    localStorage.setItem('calendarEvents', JSON.stringify(this.state.events))
  }

  getKey(date) {
    return date.toISOString().slice(0, 10)
  }

  timeToMinutes(timeStr) {
    if (!timeStr) return 24*60
    const parts = timeStr.split(' ')
    if (parts.length !== 2) return 24*60
    const [hm, ampm] = parts
    let [h, m] = hm.split(':').map(n => parseInt(n, 10))
    if (isNaN(h) || isNaN(m)) return 24*60
    if (ampm.toUpperCase() === 'PM' && h !== 12) h += 12
    if (ampm.toUpperCase() === 'AM' && h === 12) h = 0
    return h*60 + m
  }

  renderWeekdays() {
    this.weekdaysEl.innerHTML = ''
    this.weekdays.forEach(d => {
      const el = document.createElement('div')
      el.className = 'weekday'
      el.textContent = d
      this.weekdaysEl.appendChild(el)
    })
  }

  render() {
    this.renderWeekdays()
    this.daysEl.innerHTML = ''
    const year = this.state.viewDate.getFullYear()
    const month = this.state.viewDate.getMonth()
    this.monthDisplay.textContent = `${this.monthNames[month]} ${year}`

    const firstOfMonth = new Date(year, month, 1)
    const startDay = firstOfMonth.getDay()
    const daysInMonth = new Date(year, month + 1, 0).getDate()
    const prevMonthDays = new Date(year, month, 0).getDate()
    const totalCells = Math.ceil((startDay + daysInMonth)/7) * 7

    for (let i = 0; i < totalCells; i++) {
      const cell = document.createElement('button')
      cell.className = 'day'
      cell.setAttribute('role','button')
      cell.setAttribute('tabindex','0')

      let dayNum, cellDate, outside = false
      const index = i - startDay + 1
      if (index <= 0) {
        dayNum = prevMonthDays + index
        cellDate = new Date(year, month - 1, dayNum)
        outside = true
      } else if (index > daysInMonth) {
        dayNum = index - daysInMonth
        cellDate = new Date(year, month + 1, dayNum)
        outside = true
      } else {
        dayNum = index
        cellDate = new Date(year, month, dayNum)
      }

      if (outside) cell.classList.add('outside')
      const dateSpan = document.createElement('div')
      dateSpan.className = 'date'
      dateSpan.textContent = dayNum
      cell.appendChild(dateSpan)

      const key = this.getKey(cellDate)
      let evs = this.state.events[key] || []
      if (evs.length) {
        evs = evs.slice().sort((a, b) => this.timeToMinutes(a.time) - this.timeToMinutes(b.time))
        const eventsWrap = document.createElement('div')
        eventsWrap.className = 'events'
        evs.forEach((e, i) => {
          const evEl = document.createElement('div')
          evEl.textContent = e.time ? `${e.time} — ${e.name}` : e.name
          evEl.style.cursor = 'pointer'
          evEl.addEventListener('click', (event) => {
            event.stopPropagation()
            this.modal.open(cellDate, e, i)
          })
          eventsWrap.appendChild(evEl)
        })
        cell.appendChild(eventsWrap)
      }

      const todayKey = this.getKey(new Date())
      if (key === todayKey) cell.classList.add('today')

      cell.addEventListener('click', () => this.modal.open(cellDate))
      this.daysEl.appendChild(cell)
    }
  }

  changeMonth(delta) {
    const d = new Date(this.state.viewDate)
    d.setMonth(d.getMonth() + delta)
    this.state.viewDate = d
    this.render()
  }
}
