export class Modal {
  constructor(calendar) {
    this.calendar = calendar
    this.overlay = document.getElementById('modalOverlay')
    this.modalDate = document.getElementById('modalDate')
    this.eventInput = document.getElementById('eventInput')
    this.saveBtn = document.getElementById('saveBtn')
    this.cancelBtn = document.getElementById('cancelBtn')
    this.deleteBtn = document.getElementById('deleteBtn')

    this.hourSelect = document.getElementById('hour')
    this.minuteSelect = document.getElementById('minute')
    this.ampmSelect = document.getElementById('ampm')

    this.editingIndex = null
    this.bindEvents()
    this.populateTimeDropdowns()
  }

  bindEvents() {
    this.cancelBtn.addEventListener('click', () => this.close())
    this.overlay.addEventListener('click', e => {
      if (e.target === this.overlay) this.close()
    })
    this.saveBtn.addEventListener('click', () => this.save())
    this.deleteBtn.addEventListener('click', () => this.delete())
  }

  populateTimeDropdowns() {
    for (let i = 1; i <= 12; i++) {
      const opt = document.createElement('option')
      opt.value = i
      opt.textContent = i
      this.hourSelect.appendChild(opt)
    }
    for (let i = 0; i < 60; i += 5) {
      const opt = document.createElement('option')
      const val = i.toString().padStart(2, '0')
      opt.value = val
      opt.textContent = val
      this.minuteSelect.appendChild(opt)
    }
  }

  open(date, existingEvent = null, index = null) {
    this.calendar.state.selectedDate = date
    this.editingIndex = index
    this.overlay.classList.add('active')

    const dateKey = this.calendar.getKey(date)
    this.modalDate.textContent = existingEvent
      ? `Edit event for ${dateKey}`
      : `Add event for ${dateKey}`

    if (existingEvent) {
      this.eventInput.value = existingEvent.name
      const [time, ampm] = existingEvent.time.split(' ')
      const [hour, minute] = time.split(':')
      this.hourSelect.value = parseInt(hour)
      this.minuteSelect.value = minute
      this.ampmSelect.value = ampm
      this.deleteBtn.style.display = 'inline-block'
    } else {
      this.eventInput.value = ''
      this.hourSelect.value = '12'
      this.minuteSelect.value = '00'
      this.ampmSelect.value = 'AM'
      this.deleteBtn.style.display = 'none'
    }

    this.eventInput.focus()
  }

  close() {
    this.overlay.classList.remove('active')
    this.calendar.state.selectedDate = null
    this.editingIndex = null
  }

  save() {
    const name = this.eventInput.value.trim()
    if (!name) return
    const hour = this.hourSelect.value
    const minute = this.minuteSelect.value
    const ampm = this.ampmSelect.value
    const time = `${hour}:${minute} ${ampm}`
    const key = this.calendar.getKey(this.calendar.state.selectedDate)
    const existing = this.calendar.state.events[key] || []

    if (this.editingIndex !== null) {
      existing[this.editingIndex] = { name, time }
    } else {
      existing.push({ name, time })
    }

    this.calendar.state.events[key] = existing
    this.calendar.saveEvents()
    this.close()
    this.calendar.render()
  }

  delete() {
    const key = this.calendar.getKey(this.calendar.state.selectedDate)
    if (this.editingIndex !== null && this.calendar.state.events[key]) {
      this.calendar.state.events[key].splice(this.editingIndex, 1)
      if (this.calendar.state.events[key].length === 0) delete this.calendar.state.events[key]
      this.calendar.saveEvents()
      this.close()
      this.calendar.render()
    }
  }
}
