// AWS S3 Static Website Demo - JavaScript

document.addEventListener('DOMContentLoaded', function() {
    // Set timestamp
    const timestampEl = document.getElementById('timestamp');
    if (timestampEl) {
        timestampEl.textContent = new Date().toLocaleString();
    }

    // Smooth scrolling for navigation links
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function(e) {
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                target.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });

    // Navbar background on scroll
    const navbar = document.querySelector('.navbar');
    window.addEventListener('scroll', function() {
        if (window.scrollY > 50) {
            navbar.style.background = 'rgba(35, 47, 62, 0.95)';
            navbar.style.boxShadow = '0 2px 10px rgba(0, 0, 0, 0.3)';
        } else {
            navbar.style.background = '#232F3E';
            navbar.style.boxShadow = 'none';
        }
    });

    // Animate feature cards on scroll
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    };

    const observer = new IntersectionObserver(function(entries) {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.style.opacity = '1';
                entry.target.style.transform = 'translateY(0)';
            }
        });
    }, observerOptions);

    // Apply initial styles and observe feature cards
    document.querySelectorAll('.feature-card, .service-item').forEach(card => {
        card.style.opacity = '0';
        card.style.transform = 'translateY(20px)';
        card.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
        observer.observe(card);
    });

    // Console message
    console.log('%c AWS S3 Static Website Demo ',
        'background: #FF9900; color: #232F3E; font-size: 16px; padding: 10px; border-radius: 4px;');
    console.log('This website is hosted on Amazon S3 with CloudFront CDN.');
    console.log('Learn more at: https://aws.amazon.com/s3/');
});
