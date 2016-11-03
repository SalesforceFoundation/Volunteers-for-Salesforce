html body.sfdcBody {
    padding: 0 !important;
}
input.lookupInput {
    background-color: white;
    background-image: none;
    color: #16325c;
    border: 1px solid #d8dde6;
    border-radius: .25rem;
    width: 100%;
    -webkit-transition: border 0.1s linear, background-color 0.1s linear;
    transition: border 0.1s linear, background-color 0.1s linear;
    display: inline-block;
    padding: 0 1rem 0 .75rem;
    line-height: 1.875rem;
    min-height: calc(1.875rem + 2px);
    margin-right: -30px;
}

/* slds203 sets any multiselect to a smaller line height, but in visualforce, a single select looks like a multi with size=1, so this fixes the height */
.sfdo213 .slds-select[size="1"] {
    min-height: calc(1.875rem + (1px * 2));
    height: calc(1.875rem + (1px * 2));
} 

        
