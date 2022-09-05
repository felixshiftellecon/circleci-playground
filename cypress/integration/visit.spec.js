describe('Visit A Website', () => {
  it('visits the base url with /', () => {
    cy.visit('/')
  })

  it('visits the base url with Cypress.config(baseUrl)', () => {
    cy.visit(Cypress.config('baseUrl'))
  })

  it('visits the base url with Cypress.config().baseUrl', () => {
    cy.visit(Cypress.config().baseUrl)
  })
})