describe('Visit A Website', () => {

  beforeEach(function() {
    cy.task('log', Cypress.config())
  })

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